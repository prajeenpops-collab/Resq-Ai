from fastapi import APIRouter, Depends, Query
from typing import Optional

from app.core.security import require_role
from app.services import firestore_service

router = APIRouter(prefix="/dashboard", tags=["dashboard"])

DISPATCH_ROLES = ("dispatcher", "police", "ambulance", "fire", "hospital")


@router.get("/feed")
async def live_feed(
    status: Optional[str] = Query(None),
    severity: Optional[str] = Query(None),
    user: dict = Depends(require_role(*DISPATCH_ROLES)),
):
    return firestore_service.list_reports(status=status, severity=severity)


@router.get("/analytics")
async def analytics(user: dict = Depends(require_role(*DISPATCH_ROLES))):
    reports = firestore_service.list_reports(limit=500)

    by_severity = {}
    by_category = {}
    by_status = {}
    for r in reports:
        by_severity[r["severity"]] = by_severity.get(r["severity"], 0) + 1
        by_category[r["category"]] = by_category.get(r["category"], 0) + 1
        by_status[r["status"]] = by_status.get(r["status"], 0) + 1

    return {
        "total": len(reports),
        "bySeverity": by_severity,
        "byCategory": by_category,
        "byStatus": by_status,
    }
