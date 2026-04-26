import json
import logging
import tempfile

import openai
from fastapi import APIRouter, Depends, File, HTTPException, Response, UploadFile, status
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session, selectinload

from app.core.config import settings
from app.db import get_db
from app.models import Entry, EntryLink, Insight, Pointer
from app.schemas import (
    AutoLinkRequest,
    AutoLinkResponse,
    EntryCreate,
    EntryLinkCreate,
    EntryLinkRead,
    EntryRead,
    EntryUpdate,
    HealthResponse,
    InsightCreate,
    InsightRead,
    PointerCreate,
    PointerRead,
    SemanticSearchResult,
    TranscriptResponse,
)
from app.services.insight_engine import build_weekly_insight
from app.services.sort_engine import suggest_sort
from app.services.vector_service import semantic_search_recent_entries

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


@router.post("/entries/{entry_id}/link", response_model=EntryLinkRead, status_code=status.HTTP_201_CREATED)
def link_entries(entry_id: int, payload: EntryLinkCreate, db: Session = Depends(get_db)) -> EntryLink:
    if entry_id == payload.to_entry_id:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Cannot link an entry to itself",
        )

    from_entry = db.query(Entry).filter(Entry.id == entry_id).first()
    if from_entry is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Entry not found")

    to_entry = db.query(Entry).filter(Entry.id == payload.to_entry_id).first()
    if to_entry is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Target entry not found")

    link = EntryLink(
        from_entry_id=entry_id,
        to_entry_id=payload.to_entry_id,
        link_type=payload.link_type,
    )

    try:
        db.add(link)
        db.commit()
        db.refresh(link)
        return link
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Link already exists (or violates link constraints)",
        )


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


@router.post("/entries/{entry_id}/auto-link", response_model=AutoLinkResponse, status_code=status.HTTP_201_CREATED)
def auto_link_entries(entry_id: int, payload: AutoLinkRequest, db: Session = Depends(get_db)) -> AutoLinkResponse:
    if not payload.related_entry_ids:
        return AutoLinkResponse(created=0, skipped=0, links=[])

    source = db.query(Entry).filter(Entry.id == entry_id).first()
    if source is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Entry not found")

    created_links: list[EntryLink] = []
    skipped = 0

    for to_id in payload.related_entry_ids[:2]:
        if to_id == entry_id:
            skipped += 1
            continue

        target = db.query(Entry).filter(Entry.id == to_id).first()
        if target is None:
            skipped += 1
            continue

        link = EntryLink(from_entry_id=entry_id, to_entry_id=to_id, link_type=payload.link_type)
        try:
            db.add(link)
            db.commit()
            db.refresh(link)
            created_links.append(link)
        except IntegrityError:
            db.rollback()
            skipped += 1

    return AutoLinkResponse(
        created=len(created_links),
        skipped=skipped,
        links=[EntryLinkRead.model_validate(l) for l in created_links],
    )


@router.get("/entries/search/semantic", response_model=list[SemanticSearchResult])
def semantic_search_entries(
    q: str,
    k: int = 10,
    db: Session = Depends(get_db),
) -> list[SemanticSearchResult]:
    q = (q or "").strip()
    if not q:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail="Query string 'q' is required")

    k = max(1, min(int(k), 50))
    results = semantic_search_recent_entries(db, query=q, k=k, recent_limit=500)

    return [
        SemanticSearchResult(entry=EntryRead.model_validate(entry), score=score)
        for entry, score in results
    ]


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
        evidence_json=json.dumps(payload.evidence),
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
async def transcribe_audio(audio: UploadFile = File(...), db: Session = Depends(get_db)) -> TranscriptResponse:
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

        related_ids: list[int] = []
        try:
            # Constrain predictive linking to a small candidate set from semantic search.
            candidates_scored = semantic_search_recent_entries(db, query=transcript, k=8, recent_limit=500)
            candidates = [{"id": e.id, "content": e.content} for e, _score in candidates_scored]
            suggestion = suggest_sort(transcript, candidates=candidates)
            related_ids = suggestion.related_entry_ids
        except Exception:
            logger.exception("Predictive linking candidate generation failed")
            suggestion = suggest_sort(transcript)

        return TranscriptResponse(
            transcript=transcript,
            suggested_globe=suggestion.globe,
            suggested_pointers=suggestion.pointers,
            confidence=suggestion.confidence,
            suggested_related_entry_ids=related_ids,
        )

    except HTTPException:
        raise
    except Exception:
        logger.exception("Transcription failed")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to transcribe audio. Check server logs for details.",
        )
