import json
import re
from typing import Any

import httpx

from core.config import settings
from .schema import (
    TourismPlannerRequest,
    TourismPlannerResponse,
    SustainabilityPlanRequest,
    SustainabilityPlanResponse,
    Savings,
    SubsidyRecommendation,
    CurrentPlan,
    OptimizedPlan,
    PlanComparison,
)

# ---------- Goa Subsidies Database ----------

GOA_SUBSIDIES = [
    {
        "name": "Goa Solar Mission",
        "amount": "₹1,20,000",
        "description": "30% subsidy on rooftop solar for SMEs",
        "criteria": "energy",
    },
    {
        "name": "Green Tourism Grant",
        "amount": "₹50,000",
        "description": "For beach shacks adopting zero-waste practices",
        "criteria": "tourism",
    },
    {
        "name": "Biogas Plant Subsidy",
        "amount": "₹80,000",
        "description": "MNRE scheme for organic waste processors",
        "criteria": "waste",
    },
    {
        "name": "Waste to Wealth Scheme",
        "amount": "₹35,000",
        "description": "Organic + oil diversion incentive",
        "criteria": "waste",
    },
    {
        "name": "PM-KUSUM Solar Pump",
        "amount": "₹60,000",
        "description": "Solar water pump subsidy for agri-tourism",
        "criteria": "energy",
    },
]

# ---------- JSON Extraction ----------

def _extract_json(text: str) -> dict[str, Any] | None:
    try:
        return json.loads(text)
    except Exception:
        # Strip markdown code fences
        cleaned = text.replace("```json", "").replace("```", "").strip()
        try:
            return json.loads(cleaned)
        except Exception:
            pass
        match = re.search(r"\{.*\}", text, flags=re.S)
        if not match:
            return None
        try:
            return json.loads(match.group(0))
        except Exception:
            return None


# ---------- Weather ----------

async def _weather_hint(location: str) -> str:
    if not settings.OPENWEATHERMAP_API_KEY:
        return "No live weather key configured. Prefer morning/late-evening travel windows."
    url = "https://api.openweathermap.org/data/2.5/weather"
    params = {
        "q": location,
        "appid": settings.OPENWEATHERMAP_API_KEY,
        "units": "metric",
    }
    async with httpx.AsyncClient(timeout=15) as client:
        response = await client.get(url, params=params)
        if response.status_code != 200:
            return "Weather API unavailable. Use low-heat windows."
        body = response.json()
        temp = body.get("main", {}).get("temp")
        desc = body.get("weather", [{}])[0].get("description", "unknown")
        return f"Current weather in {location}: {temp}C, {desc}. Optimize outdoor segments accordingly."


# ---------- Carbon Calculation ----------

def _compute_current_carbon(distance: float, mode: str) -> float:
    factors = {
        "car": 0.12,
        "bike": 0.08,
        "bus": 0.05,
        "walking": 0.0,
    }
    return distance * factors.get(mode.lower(), 0.12)


# ---------- Prompt Builders ----------

def _strict_prompt(payload: TourismPlannerRequest, weather_hint: str) -> str:
    return f"""
You are a sustainability intelligence engine for tourism in Goa.

Given a CURRENT travel plan, your job is to:
1. Calculate its carbon footprint
2. Create an OPTIMIZED sustainable alternative itinerary
3. Compare BOTH scenarios

The optimized itinerary must:
- Reduce travel distance
- Prefer walking, cycling, or shared transport
- Include local experiences (farms, local food)
- Minimize environmental impact

Weather context:
{weather_hint}

Input JSON:
{payload.model_dump_json()}

Output STRICT JSON:
{{
  "current_plan": {{
    "carbon": "",
    "cost": "",
    "impact_summary": ""
  }},
  "optimized_plan": {{
    "itinerary": [
      {{"activity": "", "transport": "", "distance": ""}}
    ],
    "carbon": "",
    "cost": "",
    "impact_summary": ""
  }},
  "comparison": {{
    "carbon_reduction_percent": "",
    "money_saved": "",
    "experience_improvement": ""
  }},
  "emotional_message": ""
}}
""".strip()


def _sustainability_prompt(payload: SustainabilityPlanRequest, weather_hint: str) -> str:
    return f"""
You are a sustainability AI for Goa tourism businesses.

You MUST return STRICT JSON. No text outside JSON.

IMPORTANT RULES:
- Your response MUST be SPECIFIC to the exact transport mode and distance below.
- Different transport modes MUST produce COMPLETELY different suggestions.
- Use emission factors: car=0.12 kg/km, bike=0.08, bus=0.05, walking=0, auto=0.095, scooter=0.113
- Generate a REAL Indian government subsidy that fits this scenario (Goa state or central schemes)
- Include real-life analogies comparing savings to everyday things in Goa

User Input:
- Distance: {payload.distance} km
- Transport: {payload.transport_mode}
- Location: {payload.location}
- Business Type: {payload.business_type}
- Waste: {payload.waste_type or 'not specified'}
- Energy: {payload.energy_usage or 'not specified'}

Weather: {weather_hint}

Format:
{{
  "insight": "1-2 sentence analysis of current impact with the SPECIFIC transport mode and distance",
  "current": {{
    "carbon": "X.X kg CO2",
    "cost": "Rs XXXX"
  }},
  "optimized": {{
    "plan": ["Step 1: specific action for this mode", "Step 2: ...", "Step 3: ...", "Step 4: ..."],
    "carbon": "X.X kg CO2",
    "cost": "Rs XXXX"
  }},
  "savings": {{
    "carbon_reduction": "XX%",
    "money_saved": "Rs XXX"
  }},
  "subsidy": {{
    "name": "Real Indian govt scheme name",
    "amount": "Rs XX,XXX",
    "reason": "Why this scheme fits based on the user's specific scenario"
  }},
  "analysis": [
    "Equivalent to planting X coconut trees in Goa",
    "Like removing X auto-rickshaws from Panaji roads for a day",
    "Saves enough energy to power X Goan households for a day",
    "Equal to X fewer plastic bags in Goa's beaches"
  ]
}}

Return JSON only.
""".strip()


# ---------- AI Providers ----------

async def _call_groq(prompt: str) -> dict[str, Any] | None:
    if not settings.GROQ_API_KEY:
        return None
    headers = {
        "Authorization": f"Bearer {settings.GROQ_API_KEY}",
        "Content-Type": "application/json",
    }
    body = {
        "model": "llama-3.3-70b-versatile",
        "temperature": 0.5,
        "messages": [
            {"role": "system", "content": "Return only valid JSON. No markdown."},
            {"role": "user", "content": prompt},
        ],
    }
    async with httpx.AsyncClient(timeout=30) as client:
        response = await client.post(
            "https://api.groq.com/openai/v1/chat/completions",
            headers=headers,
            json=body,
        )
        if response.status_code != 200:
            print(f"Groq returned {response.status_code}: {response.text[:200]}")
            return None
        text = response.json()["choices"][0]["message"]["content"]
        return _extract_json(text)


async def _call_openrouter(prompt: str) -> dict[str, Any] | None:
    if not settings.OPENROUTER_API_KEY:
        return None
    headers = {
        "Authorization": f"Bearer {settings.OPENROUTER_API_KEY}",
        "Content-Type": "application/json",
        "HTTP-Referer": "https://goagreen.app",
        "X-Title": "GoaGreen Sustainability",
    }
    body = {
        "model": "mistralai/mixtral-8x7b-instruct",
        "temperature": 0.2,
        "messages": [
            {"role": "system", "content": "Return only valid JSON. No markdown."},
            {"role": "user", "content": prompt},
        ],
    }
    async with httpx.AsyncClient(timeout=30) as client:
        response = await client.post(
            "https://openrouter.ai/api/v1/chat/completions",
            headers=headers,
            json=body,
        )
        if response.status_code != 200:
            print(f"OpenRouter returned {response.status_code}: {response.text[:200]}")
            return None
        text = response.json()["choices"][0]["message"]["content"]
        return _extract_json(text)


async def _call_gemini(prompt: str) -> dict[str, Any] | None:
    if not settings.GEMINI_API_KEY:
        return None
    url = (
        "https://generativelanguage.googleapis.com/v1beta/models/"
        f"gemini-1.5-flash:generateContent?key={settings.GEMINI_API_KEY}"
    )
    body = {
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {"temperature": 0.2},
    }
    async with httpx.AsyncClient(timeout=30) as client:
        response = await client.post(url, json=body)
        if response.status_code != 200:
            print(f"Gemini returned {response.status_code}: {response.text[:200]}")
            return None
        text = response.json()["candidates"][0]["content"]["parts"][0]["text"]
        return _extract_json(text)


# ---------- Local Subsidy Matcher ----------

def _match_subsidy_locally(carbon_reduction: str, waste_type: str = "") -> dict:
    """Backup local subsidy matcher when AI doesn't return one."""
    # If carbon reduction is high, suggest Green Tourism Grant
    try:
        pct = float(re.sub(r"[^0-9.]", "", carbon_reduction))
    except (ValueError, TypeError):
        pct = 0

    if pct >= 30:
        return {
            "name": "Green Tourism Grant",
            "amount": "₹50,000",
            "reason": f"Your {carbon_reduction} carbon reduction qualifies for zero-waste tourism incentive",
        }
    if "oil" in waste_type.lower() or "waste" in waste_type.lower():
        return {
            "name": "Waste to Wealth Scheme",
            "amount": "₹35,000",
            "reason": "Organic + oil waste diversion qualifies for this incentive",
        }
    return {
        "name": "Goa Solar Mission",
        "amount": "₹1,20,000",
        "reason": "Rooftop solar reduces your grid dependency and emissions",
    }


# ---------- Fallbacks ----------

def _fallback(payload: TourismPlannerRequest) -> dict[str, Any]:
    current_carbon = _compute_current_carbon(payload.distance, payload.transport_mode)
    optimized_carbon = max(current_carbon * 0.62, 0.0)
    return {
        "current_plan": {
            "carbon": f"{current_carbon:.2f} kg CO2",
            "cost": "Rs 2400",
            "impact_summary": "Current routing has avoidable fossil-heavy segments.",
        },
        "optimized_plan": {
            "itinerary": [
                {
                    "activity": "Morning coastal cycling with local breakfast stop",
                    "transport": "cycling",
                    "distance": "4 km",
                },
                {
                    "activity": "Farm-to-table lunch and spice farm walk",
                    "transport": "walking",
                    "distance": "2 km",
                },
                {
                    "activity": "Shared electric shuttle to heritage market",
                    "transport": "shared transport",
                    "distance": "6 km",
                },
            ],
            "carbon": f"{optimized_carbon:.2f} kg CO2",
            "cost": "Rs 1850",
            "impact_summary": "Shorter loops, lower emissions, stronger local experience density.",
        },
        "comparison": {
            "carbon_reduction_percent": "38%",
            "money_saved": "Rs 550",
            "experience_improvement": "More local food, farm engagement, and low-stress movement.",
        },
        "emotional_message": "This route helps preserve Goa's coast while supporting local livelihoods.",
    }


def _sustainability_fallback(payload: SustainabilityPlanRequest) -> dict[str, Any]:
    current_carbon = _compute_current_carbon(payload.distance, payload.transport_mode)
    optimized_carbon = max(current_carbon * 0.62, 0.0)
    reduction_pct = round((1 - optimized_carbon / max(current_carbon, 0.01)) * 100)
    money_saved = round(payload.distance * 3.5)

    subsidy = _match_subsidy_locally(f"{reduction_pct}%", payload.waste_type)

    return {
        "insight": f"Your {payload.distance}km {payload.transport_mode} trip emits {current_carbon:.1f} kg CO2. Switching to eco modes can cut this by {reduction_pct}%.",
        "current": {
            "carbon": f"{current_carbon:.1f} kg CO2",
            "cost": f"Rs {round(payload.distance * 12)}",
        },
        "optimized": {
            "plan": [
                f"Step 1: Morning coastal cycling to nearest eco-stop (4 km)",
                f"Step 2: Farm-to-table lunch + spice farm walk (2 km walking)",
                f"Step 3: Shared electric shuttle to heritage market (6 km)",
                f"Step 4: Evening beach cleanup walk returning to base (3 km)",
            ],
            "carbon": f"{optimized_carbon:.1f} kg CO2",
            "cost": f"Rs {round(payload.distance * 7.5)}",
        },
        "savings": {
            "carbon_reduction": f"{reduction_pct}%",
            "money_saved": f"Rs {money_saved}",
        },
        "subsidy": subsidy,
    }


# ---------- Main Service Functions ----------

async def optimize_tourism_plan(payload: TourismPlannerRequest) -> TourismPlannerResponse:
    weather = await _weather_hint(payload.location)
    prompt = _strict_prompt(payload, weather)

    # Chain: Groq → OpenRouter → Gemini → Local fallback
    result = await _call_groq(prompt)
    if result is None:
        result = await _call_openrouter(prompt)
    if result is None:
        result = await _call_gemini(prompt)
    if result is None:
        result = _fallback(payload)

    return TourismPlannerResponse.model_validate(result)


async def get_sustainability_plan(payload: SustainabilityPlanRequest) -> SustainabilityPlanResponse:
    weather = await _weather_hint(payload.location)
    prompt = _sustainability_prompt(payload, weather)

    source = "fallback"
    result = None

    # 🥇 PRIMARY → GROQ
    try:
        print("[AI] Using Groq...")
        result = await _call_groq(prompt)
        if result:
            source = "groq"
    except Exception as e:
        print(f"[ERR] Groq ERROR: {e}")

    # 🥈 FALLBACK 1 → OPENROUTER
    if result is None:
        try:
            print("[AI] Switching to OpenRouter...")
            result = await _call_openrouter(prompt)
            if result:
                source = "openrouter"
        except Exception as e:
            print(f"[ERR] OpenRouter ERROR: {e}")

    # 🥉 FALLBACK 2 → GEMINI
    if result is None:
        try:
            print("[AI] Switching to Gemini...")
            result = await _call_gemini(prompt)
            if result:
                source = "gemini"
        except Exception as e:
            print(f"[ERR] Gemini ERROR: {e}")

    # 🔧 FINAL FALLBACK → LOCAL
    if result is None:
        print("[WARN] All AI providers failed. Using local fallback...")
        result = _sustainability_fallback(payload)
        source = "fallback"

    # Ensure subsidy is present (backup local match)
    if not result.get("subsidy") or not result["subsidy"].get("name"):
        carbon_reduction = (result.get("savings") or {}).get("carbon_reduction", "30%")
        result["subsidy"] = _match_subsidy_locally(carbon_reduction, payload.waste_type)

    # Ensure analysis has real-life analogies
    analysis = result.get("analysis", [])
    if not analysis:
        current_carbon = _compute_current_carbon(payload.distance, payload.transport_mode)
        saved = current_carbon * 0.38
        analysis = [
            f"Equivalent to planting {max(1, int(saved / 0.022))} coconut trees in Goa",
            f"Like removing {max(1, int(saved / 2.4))} auto-rickshaws from Panaji roads for a day",
            f"Saves enough energy to power {max(1, int(saved / 0.82))} Goan households for a day",
        ]

    # Build response
    savings_data = result.get("savings", {})
    subsidy_data = result.get("subsidy", {})

    current_plan = None
    optimized_plan = None
    comparison = None
    if result.get("current"):
        current_plan = CurrentPlan(
            carbon=result["current"].get("carbon", ""),
            cost=result["current"].get("cost", ""),
            impact_summary=result.get("insight", ""),
        )
    if result.get("optimized"):
        opt = result["optimized"]
        optimized_plan = OptimizedPlan(
            plan=opt.get("plan", []),
            carbon=opt.get("carbon", ""),
            cost=opt.get("cost", ""),
            impact_summary="Eco-optimized route with lower emissions",
        )
    if result.get("savings"):
        comparison = PlanComparison(
            carbon_reduction_percent=savings_data.get("carbon_reduction", ""),
            money_saved=savings_data.get("money_saved", ""),
            experience_improvement="More authentic local experiences with lower impact",
        )

    return SustainabilityPlanResponse(
        insight=result.get("insight", ""),
        current=result.get("current", {}),
        optimized=result.get("optimized", {}),
        savings=Savings(**savings_data) if savings_data else Savings(),
        subsidy=SubsidyRecommendation(**subsidy_data) if subsidy_data else SubsidyRecommendation(),
        analysis=analysis,
        current_plan=current_plan,
        optimized_plan=optimized_plan,
        comparison=comparison,
        emotional_message=result.get("emotional_message", "Every green choice helps preserve Goa for generations."),
        source=source,
    )
