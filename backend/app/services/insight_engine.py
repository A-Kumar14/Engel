from sqlalchemy import func
from sqlalchemy.orm import Session

from app.models import Entry, GlobeType, Insight, InsightType


def build_weekly_insight(db: Session) -> Insight | None:
    green_count = db.query(func.count(Entry.id)).filter(Entry.globe == GlobeType.GREEN).scalar() or 0
    red_count = db.query(func.count(Entry.id)).filter(Entry.globe == GlobeType.RED).scalar() or 0

    if green_count == 0 and red_count == 0:
        return None

    if green_count == red_count:
        return Insight(
            insight_type=InsightType.QUESTION,
            title="Balanced signals this week",
            body="Green and red entries are evenly matched. Open the latest entries together and decide what that balance means.",
            evidence_summary=f"{green_count} green entries and {red_count} red entries detected.",
        )

    dominant_globe = "green" if green_count > red_count else "red"
    gap = abs(green_count - red_count)

    return Insight(
        insight_type=InsightType.ASYMMETRY,
        title=f"{dominant_globe.title()} globe is louder this week",
        body=f"The {dominant_globe} globe has {gap} more entries than the other globe. That difference may be worth reviewing, without forcing an interpretation.",
        evidence_summary=f"{green_count} green entries and {red_count} red entries detected.",
    )
