# Goa Sustainability App - Business Mode

This document provides a comprehensive overview of the **Business Mode** features implemented in the Goa Sustainability App, detailing the safety, compliance, and carbon credit functionalities built to support local businesses.

---

## 1. Safety & Compliance Layer

To ensure businesses receive accurate, non-misleading information and to minimize legal liability for the platform, a robust safety layer has been implemented.

### 1.1 Persistent Disclaimer Banner
- **`DisclaimerBanner` Widget**: A globally reusable, visually distinct banner that persists across sessions using `SharedPreferences`.
- **Purpose**: Displays crucial legal disclaimers ensuring the business understands the AI-generated nature of certain analyses and the necessity of official verification.
- **Locations**: Prominently displayed above Carbon Credit Analyses and Subsidy Application portals.

### 1.2 Verified Assessment Paths
- Removed hallucination-prone AI guidance for real-world legal processes.
- **"Get Verified" CTA**: Added direct, hardcoded links below carbon credit verdicts directing users to accredited entities (BEE India, Verra, Boomitra, Varaha).

### 1.3 Strict "Other" Sector Safeguards
- **Blocklist**: Hardcoded blocklist to instantly reject analyses for restricted business types (e.g., weapons, tobacco, gambling).
- **Confidence Scoring**: The AI engine explicitly returns an `analysis_confidence` score and `is_standard_sector` flag. 
- **Warning Banners**: Displays specific warning UI for low-confidence or non-standard sectors, advising the user that the data is highly experimental.

---

## 2. Emission Transparency & Calculation

### 2.1 Hardcoded Emission Factors
- **`emission_factors.dart`**: Centralized, offline fallback calculation engine.
- **Data Integrity**: Uses static, verified constants sourced directly from the **India GHG Platform**, **IPCC AR6**, and **BEE India**.
- **Usage**: Automatically steps in when the AI engine is offline or when calculating base values before AI prompt enrichment.

### 2.2 Scope 1, 2, and 3 Transparency
- **`ScopeBadge` Widget**: Interactive UI chips placed directly beside every user input field (e.g., "Electricity kWh" → Scope 2, "LPG kg" → Scope 1).
- **Tooltips**: Clicking a Scope 3 badge explains why these indirect emissions cannot be used to generate carbon credits.
- **AI Constraints**: The LLM prompt is strictly engineered to *exclude* Scope 3 emissions when calculating carbon credit opportunities, ensuring realistic viability estimates.

---

## 3. Carbon Credit Intelligence (Exchange Section)

The entire Carbon Credit analysis has been integrated into the **Exchange Section**, transforming it into a holistic resource marketplace and monetization dashboard.

### 3.1 Realistic Viability Thresholds
- **Micro-Projects (< 50 tonnes)**: Flags projects as too small for the market, advising a focus on cost savings instead.
- **Small Projects (< 500 tonnes)**: Advises that solo registration is impossible; provides direct links to aggregators (e.g., Varaha, Boomitra).
- **Viable Projects (> 500 tonnes)**: Recommends independent registration and professional assessment.

### 3.2 Revenue & Cost Warnings
- **Hidden Cost Disclosure**: Every revenue estimate explicitly states that it does not account for the ₹40L–₹4Cr project development and verification costs required for independent registration.

### 3.3 Market Data & Quality Flags
- **ICVCM Reality Check**: Includes hardcoded warnings regarding Renewable Energy credits (solar/wind), noting that they are increasingly rejected by ICVCM due to additionality concerns.
- **Data Timestamps**: All market insights include a "Data as of March 2025" label for transparency.

---

## 4. Subsidies & Government Schemes

### 4.1 Hardcoded Subsidy Database
- **`subsidy_database.dart`**: Replaced all dynamic AI-generated subsidy application guides with a hardcoded, deterministic database.
- **Accuracy**: Ensures businesses get the exact, official eligibility criteria and physical Goa office addresses (e.g., GEDA, MSME ZED).
- **Actionable Links**: Uses `url_launcher` to securely route users to official portals (`bee.gov.in`, `geda.goa.gov.in`) rather than offering hallucinated application steps.

---

## 5. Interactive Carbon Action Plan

### 5.1 Gamified Persistence
- **`CarbonActionTracker`**: Replaced static text lists with an interactive checklist.
- **SharedPreferences Integration**: Action items persist locally.
- **Eco-Score Loop**: Completing tasks on the action plan dynamically boosts the user's `ecoScore` (gamification loop), providing immediate positive feedback for sustainable behavior.

---

## 6. Sector-Specific Features

### 6.1 Tourism
- Focuses on transport mode, electricity, LPG, and organic waste.
- Real-time trip emissions tracking.

### 6.2 Cashew
- Focuses on roasting fuels (firewood vs. biomass), shell waste, and CNSL oil extraction.
- **Biochar Warning**: Hardcoded warning that Biochar credits ($100–200/t) require high-CAPEX pyrolysis units (₹15L–₹1Cr) and specific Puro.earth registration, setting realistic expectations.

### 6.3 Farmer
- Tracks crop type, irrigation methods, fertilizers, and pesticide usage.
- Links explicitly to agricultural aggregators for credit viability.

### 6.4 Bakery
- Focuses on oven fuel types, flour/butter supply chain (Scope 3), and organic bread waste.

### 6.5 Custom ("Other")
- Flexible input schema protected by the Blocklist and Confidence Scoring systems detailed above.

---
*Document last updated: April 2026*
