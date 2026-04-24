from datetime import datetime
from enum import Enum

from sqlalchemy import DateTime, Enum as SqlEnum, ForeignKey, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db import Base


class GlobeType(str, Enum):
    GREEN = "green"
    RED = "red"
    UNSORTED = "unsorted"


class InsightType(str, Enum):
    ASYMMETRY = "asymmetry"
    CONTRADICTION = "contradiction"
    DRIFT = "drift"
    SILENCE = "silence"
    REALITY_CHECK = "reality_check"
    QUESTION = "question"


class Entry(Base):
    __tablename__ = "entries"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    content: Mapped[str] = mapped_column(Text, nullable=False)
    source: Mapped[str] = mapped_column(String(32), default="text")
    globe: Mapped[GlobeType] = mapped_column(SqlEnum(GlobeType), default=GlobeType.UNSORTED)
    ai_confidence: Mapped[str | None] = mapped_column(String(16), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    pointers: Mapped[list["Pointer"]] = relationship(
        back_populates="entry",
        cascade="all, delete-orphan",
    )


class Pointer(Base):
    __tablename__ = "pointers"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    entry_id: Mapped[int] = mapped_column(ForeignKey("entries.id", ondelete="CASCADE"))
    label: Mapped[str] = mapped_column(String(64), nullable=False)
    source: Mapped[str] = mapped_column(String(16), default="ai")

    entry: Mapped[Entry] = relationship(back_populates="pointers")


class Insight(Base):
    __tablename__ = "insights"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    insight_type: Mapped[InsightType] = mapped_column(SqlEnum(InsightType), nullable=False)
    title: Mapped[str] = mapped_column(String(120), nullable=False)
    body: Mapped[str] = mapped_column(Text, nullable=False)
    evidence_summary: Mapped[str] = mapped_column(Text, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
