from datetime import datetime, timezone, timedelta, date
from collections import Counter

from fastapi import APIRouter, Depends, HTTPException, Query

from app.auth import get_current_user
from app.models.activity import ActivityCreate, ActivityResponse, WeeklyResponse, WrappedResponse
from app.logic.emission_factors import analogy, coins_for_activity
from app import db_ops

router = APIRouter()


def _calc_streak(user_id: str, user: dict, now: datetime) -> int:
    today = now.date()
    last = db_ops.get_last_activity(user_id)
    current_streak = user.get("streak_days", 0)

    if not last:
        return 1
    logged = last["logged_at"]
    if isinstance(logged, str):
        last_date = datetime.fromisoformat(logged.replace("Z", "+00:00")).date()
    else:
        last_date = logged.date()

    delta = (today - last_date).days
    if delta == 0:
        return current_streak
    elif delta == 1:
        return current_streak + 1
    else:
        return 1


@router.post("", response_model=ActivityResponse)
def create_activity(body: ActivityCreate, user_id: str = Depends(get_current_user)):
    user = db_ops.get_user(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    now = datetime.now(timezone.utc)
    analogy_str = analogy(body.co2_kg)
    coins = coins_for_activity(body.co2_kg)
    new_coins = user.get("green_coins", 0) + coins
    new_co2 = user.get("total_co2_saved", 0) + (body.co2_kg if body.is_saving else 0)
    new_streak = _calc_streak(user_id, user, now)

    db_ops.update_user(user_id, {"green_coins": new_coins, "total_co2_saved": new_co2, "streak_days": new_streak})

    activity = db_ops.insert_activity({
        "user_id": user_id, "title": body.title, "category": body.category.value,
        "co2_kg": body.co2_kg, "is_saving": body.is_saving,
        "analogy": analogy_str, "logged_at": now.isoformat(),
    })

    return ActivityResponse(
        id=activity["id"], title=activity["title"], category=activity["category"],
        co2_kg=activity["co2_kg"], is_saving=activity["is_saving"],
        analogy=activity.get("analogy", ""), logged_at=activity["logged_at"],
    )


@router.get("", response_model=list[ActivityResponse])
def list_activities_ep(
    limit: int = Query(20, ge=1, le=100), offset: int = Query(0, ge=0),
    category: str | None = Query(None), user_id: str = Depends(get_current_user),
):
    acts = db_ops.list_activities(user_id, limit, offset, category)
    return [
        ActivityResponse(
            id=a["id"], title=a["title"], category=a["category"], co2_kg=a["co2_kg"],
            is_saving=a["is_saving"], analogy=a.get("analogy", ""), logged_at=a["logged_at"],
        ) for a in acts
    ]


@router.get("/weekly", response_model=WeeklyResponse)
def weekly_summary(user_id: str = Depends(get_current_user)):
    today = datetime.now(timezone.utc).date()
    monday = today - timedelta(days=today.weekday())
    sunday = monday + timedelta(days=6)
    start = datetime.combine(monday, datetime.min.time()).replace(tzinfo=timezone.utc).isoformat()
    end = datetime.combine(sunday, datetime.max.time()).replace(tzinfo=timezone.utc).isoformat()

    acts = db_ops.get_activities_in_range(user_id, start, end)
    days = [0.0] * 7
    for a in acts:
        logged = a["logged_at"]
        if isinstance(logged, str):
            dt = datetime.fromisoformat(logged.replace("Z", "+00:00"))
        else:
            dt = logged
        days[dt.weekday()] += a["co2_kg"]
    return WeeklyResponse(days=[round(d, 1) for d in days])


@router.get("/wrapped", response_model=WrappedResponse)
def wrapped_summary(user_id: str = Depends(get_current_user)):
    user = db_ops.get_user(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    activities = db_ops.get_all_activities(user_id)
    co2_saved = user.get("total_co2_saved", 0)
    trees = int(co2_saved / 7.3) if co2_saved else 0

    cats: Counter = Counter()
    week_totals: dict[str, float] = {}
    for a in activities:
        cats[a["category"]] += 1
        if a.get("is_saving") and a.get("logged_at"):
            logged = a["logged_at"]
            dt = datetime.fromisoformat(logged.replace("Z", "+00:00")) if isinstance(logged, str) else logged
            iso = dt.isocalendar()
            wk = f"{iso[0]}-W{iso[1]:02d}"
            week_totals[wk] = week_totals.get(wk, 0) + a["co2_kg"]

    top_cat = cats.most_common(1)[0][0].capitalize() if cats else "None"
    if week_totals:
        best_wk = max(week_totals, key=week_totals.get)
        y, w = best_wk.split("-W")
        fd = date.fromisocalendar(int(y), int(w), 1)
        ld = fd + timedelta(days=6)
        best_week = f"{fd.strftime('%B')} {fd.day}-{ld.day}"
    else:
        best_week = "N/A"

    all_u = db_ops.get_all_users_co2()
    total_u = len(all_u)
    percentile = int((sum(1 for u in all_u if (u.get("total_co2_saved", 0) or 0) < co2_saved) / total_u) * 100) if total_u > 1 else 100

    return WrappedResponse(
        co2_saved=co2_saved, trees_equivalent=trees, top_category=top_cat,
        best_week=best_week, percentile=percentile, activities_logged=len(activities),
        green_coins_earned=user.get("green_coins", 0),
    )
