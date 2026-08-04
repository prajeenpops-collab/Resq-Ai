import base64
from fastapi import APIRouter, Depends, HTTPException
import httpx

from app.core.security import get_current_user
from app.models.emergency import EmergencyReportCreate, EmergencyReportResponse, EmergencyReportUpdate
from app.services import firestore_service, gemini_service, fcm_service, protocol_service

router = APIRouter(prefix="/emergency", tags=["emergency"])



async def _fetch_media_bytes(url: str) -> bytes:
    async with httpx.AsyncClient() as client:
        r = await client.get(url, timeout=15)
        r.raise_for_status()
        return r.content


@router.post("/report", response_model=EmergencyReportResponse)
async def submit_report(payload: EmergencyReportCreate, user: dict = Depends(get_current_user)):
    """
    Citizen submits a report (text/voice/image). Media is already uploaded to
    Firebase Storage client-side; this endpoint receives the URL, runs AI
    triage, persists the report, and notifies dispatchers.
    """
    raw_text = payload.rawText
    image_bytes, image_mime = None, None

    if payload.type == "voice" and payload.mediaUrl:
        audio_bytes = await _fetch_media_bytes(payload.mediaUrl)
        raw_text = await gemini_service.transcribe_audio(audio_bytes)

    if payload.type == "image" and payload.mediaUrl:
        image_bytes = await _fetch_media_bytes(payload.mediaUrl)
        image_mime = "image/jpeg"

    if not raw_text and not image_bytes:
        raise HTTPException(status_code=400, detail="Report must contain text, voice, or image content")

    ai_result = await gemini_service.analyze_emergency(raw_text, image_bytes, image_mime)

    report_id = firestore_service.create_report({
        "userId": user["uid"],
        "type": payload.type,
        "rawText": raw_text,
        "mediaUrl": payload.mediaUrl,
        "location": {"lat": payload.location.lat, "lng": payload.location.lng},
        "address": payload.address,
        "aiSummary": ai_result["aiSummary"],
        "category": ai_result["category"],
        "severity": ai_result["severity"],
        "firstAidGuidance": ai_result["firstAidGuidance"],
    })

    firestore_service.log_incident(report_id, "created", user["uid"])
    fcm_service.notify_dispatchers(report_id, ai_result["category"], ai_result["severity"])

    # Auto-execute emergency response protocol workflow
    try:
        protocol_service.execute_protocol(report_id)
    except Exception as e:
        pass

    report = firestore_service.get_report(report_id)
    return EmergencyReportResponse(
        reportId=report_id,
        category=report["category"],
        severity=report["severity"],
        aiSummary=report["aiSummary"],
        firstAidGuidance=report["firstAidGuidance"],
        status=report["status"],
        createdAt=report["createdAt"],
    )


@router.get("/report/{report_id}")
async def get_report(report_id: str, user: dict = Depends(get_current_user)):
    report = firestore_service.get_report(report_id)
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")
    return report


@router.get("/reports/mine")
async def my_reports(user: dict = Depends(get_current_user)):
    """Citizen's incident history."""
    all_reports = firestore_service.list_reports()
    return [r for r in all_reports if r.get("userId") == user["uid"]]


@router.patch("/report/{report_id}")
async def update_report(report_id: str, payload: EmergencyReportUpdate, user: dict = Depends(get_current_user)):
    if user["role"] not in ("dispatcher", "police", "ambulance", "fire", "hospital"):
        raise HTTPException(status_code=403, detail="Not authorized to update reports")

    updates = payload.model_dump(exclude_none=True)
    if not updates:
        raise HTTPException(status_code=400, detail="No fields to update")

    firestore_service.update_report(report_id, updates)
    firestore_service.log_incident(report_id, "status_changed", user["uid"], str(updates))
    return {"reportId": report_id, "updated": list(updates.keys())}
