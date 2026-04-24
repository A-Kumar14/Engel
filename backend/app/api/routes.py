import logging
import tempfile

import openai
from fastapi import APIRouter, Depends, File, HTTPException, Response, UploadFile, status
from sqlalchemy.orm import Session, selectinload

from app.core.config import settings
from app.db import get_db
from app.models import Entry, Insight, Pointer
from app.schemas import (
    EntryCreate,
    EntryRead,
    EntryUpdate,
    HealthResponse,
    InsightCreate,
    InsightRead,
    PointerCreate,
    PointerRead,
    TranscriptResponse,
)
from app.services.insight_engine import build_weekly_insight
from app.services.sort_engine import suggest_sort

logger = logging.getLogger(__name__)

router = APIRouter(prefix=settings.api_prefix)


@router.get("/health", response_model=HealthResponse)
def healthcheck() -> HealthResponse:
    return HealthResponse(status="ok", app=settings.app_name)


@router.get("/entries", response_model=list[EntryRead])
def list_entries(db: Session = Depends(get_db)) -> list[Entry]:
    return (
        db.query(Entry)
        .options(selectinload(Entry.pointers))
        .order_by(Entry.created_at.desc())
        .all()
    )


@router.post("/entries", response_model=EntryRead, status_code=status.HTTP_201_CREATED)
def create_entry(payload: EntryCreate, db: Session = Depends(get_db)) -> Entry:
    entry = Entry(
        content=payload.content,
        source=payload.source,
        globe=payload.globe,
        ai_confidence=payload.ai_confidence,
    )

    for pointer in payload.pointers:
        entry.pointers.append(Pointer(label=pointer.label, source=pointer.source))

    db.add(entry)
    db.commit()
    db.refresh(entry)
    return entry


@router.patch("/entries/{entry_id}", response_model=EntryRead)
def update_entry(entry_id: int, payload: EntryUpdate, db: Session = Depends(get_db)) -> Entry:
    entry = (
        db.query(Entry)
        .options(selectinload(Entry.pointers))
        .filter(Entry.id == entry_id)
        .first()
    )
    if entry is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Entry not found")

    updates = payload.model_dump(exclude_unset=True)
    for field, value in updates.items():
        setattr(entry, field, value)

    db.add(entry)
    db.commit()
    db.refresh(entry)
    return entry


@router.delete("/entries/{entry_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_entry(entry_id: int, db: Session = Depends(get_db)) -> Response:
    entry = db.query(Entry).filter(Entry.id == entry_id).first()
    if entry is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Entry not found")

    db.delete(entry)
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post("/entries/{entry_id}/pointers", response_model=PointerRead, status_code=status.HTTP_201_CREATED)
def add_pointer(entry_id: int, payload: PointerCreate, db: Session = Depends(get_db)) -> Pointer:
    entry = db.query(Entry).filter(Entry.id == entry_id).first()
    if entry is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Entry not found")

    pointer = Pointer(entry_id=entry_id, label=payload.label, source=payload.source)
    db.add(pointer)
    db.commit()
    db.refresh(pointer)
    return pointer


@router.get("/insights", response_model=list[InsightRead])
def list_insights(db: Session = Depends(get_db)) -> list[Insight]:
    return db.query(Insight).order_by(Insight.created_at.desc()).all()


@router.post("/insights", response_model=InsightRead, status_code=status.HTTP_201_CREATED)
def create_insight(payload: InsightCreate, db: Session = Depends(get_db)) -> Insight:
    insight = Insight(
        insight_type=payload.insight_type,
        title=payload.title,
        body=payload.body,
        evidence_summary=payload.evidence_summary,
    )
    db.add(insight)
    db.commit()
    db.refresh(insight)
    return insight


@router.post("/insights/weekly", response_model=InsightRead, status_code=status.HTTP_201_CREATED)
def generate_weekly_insight(db: Session = Depends(get_db)) -> Insight:
    latest = build_weekly_insight(db)
    if latest is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Not enough entry data to generate an insight",
        )

    db.add(latest)
    db.commit()
    db.refresh(latest)
    return latest


@router.post("/transcribe", response_model=TranscriptResponse)
async def transcribe_audio(audio: UploadFile = File(...)) -> TranscriptResponse:
    if not settings.openai_api_key:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="OPENAI_API_KEY is not configured on the server.",
        )

    try:
        with tempfile.NamedTemporaryFile(suffix=".m4a", delete=True) as tmp:
            content = await audio.read()
            tmp.write(content)
            tmp.flush()

            client = openai.OpenAI(api_key=settings.openai_api_key)
            with open(tmp.name, "rb") as audio_file:
                transcription = client.audio.transcriptions.create(
                    model="whisper-1",
                    file=audio_file,
                )

        transcript = transcription.text.strip()
        if not transcript:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Whisper returned an empty transcript.",
            )

        suggestion = suggest_sort(transcript)

        return TranscriptResponse(
            transcript=transcript,
            suggested_globe=suggestion.globe,
            suggested_pointers=suggestion.pointers,
            confidence=suggestion.confidence,
        )

    except HTTPException:
        raise
    except Exception:
        logger.exception("Transcription failed")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to transcribe audio. Check server logs for details.",
        )
