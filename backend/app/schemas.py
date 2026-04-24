from datetime import datetime

from pydantic import BaseModel, Field

from app.models import GlobeType, InsightType


class PointerBase(BaseModel):
    label: str = Field(min_length=1, max_length=64)
    source: str = Field(default="ai", max_length=16)


class PointerCreate(PointerBase):
    pass


class PointerRead(PointerBase):
    id: int

    model_config = {"from_attributes": True}


class EntryCreate(BaseModel):
    content: str = Field(min_length=1)
    source: str = Field(default="text", max_length=32)
    globe: GlobeType = GlobeType.UNSORTED
    ai_confidence: str | None = Field(default=None, max_length=16)
    pointers: list[PointerCreate] = []


class EntryUpdate(BaseModel):
    content: str | None = Field(default=None, min_length=1)
    source: str | None = Field(default=None, max_length=32)
    globe: GlobeType | None = None
    ai_confidence: str | None = Field(default=None, max_length=16)


class EntryRead(BaseModel):
    id: int
    content: str
    source: str
    globe: GlobeType
    ai_confidence: str | None
    created_at: datetime
    pointers: list[PointerRead]

    model_config = {"from_attributes": True}


class InsightCreate(BaseModel):
    insight_type: InsightType
    title: str = Field(min_length=1, max_length=120)
    body: str = Field(min_length=1)
    evidence_summary: str = Field(min_length=1)


class InsightRead(BaseModel):
    id: int
    insight_type: InsightType
    title: str
    body: str
    evidence_summary: str
    created_at: datetime

    model_config = {"from_attributes": True}


class TranscriptResponse(BaseModel):
    transcript: str
    suggested_globe: str
    suggested_pointers: list[str]
    confidence: float


class HealthResponse(BaseModel):
    status: str
    app: str
