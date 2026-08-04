from datetime import datetime, timezone
import uuid
from typing import Dict, List, Optional
from google.cloud.firestore_v1 import GeoPoint
from app.core.firebase import db

REPORTS = "emergency_reports"
NOTIFICATIONS = "notifications"
LOGS = "incident_logs"

# In-memory store fallback when Firestore is unavailable locally
_in_memory_reports: Dict[str, dict] = {}
_in_memory_logs: List[dict] = []
_in_memory_notifications: List[dict] = []


def create_report(data: dict) -> str:
    now = datetime.now(timezone.utc)
    report_id = str(uuid.uuid4())

    loc_obj = data.get("location", {"lat": 37.7749, "lng": -122.4194})
    lat, lng = loc_obj.get("lat", 37.7749), loc_obj.get("lng", -122.4194)

    payload = {
        **data,
        "reportId": report_id,
        "location": {"lat": lat, "lng": lng},
        "status": data.get("status", "pending"),
        "assignedResources": data.get("assignedResources", []),
        "createdAt": now.isoformat(),
        "updatedAt": now.isoformat(),
    }

    if db is not None:
        try:
            doc_ref = db.collection(REPORTS).document(report_id)
            db_payload = {
                **payload,
                "location": GeoPoint(lat, lng),
                "createdAt": now,
                "updatedAt": now,
            }
            doc_ref.set(db_payload)
        except Exception:
            pass

    _in_memory_reports[report_id] = payload
    return report_id


def get_report(report_id: str) -> Optional[dict]:
    if db is not None:
        try:
            doc = db.collection(REPORTS).document(report_id).get()
            if doc.exists:
                return {"reportId": doc.id, **doc.to_dict()}
        except Exception:
            pass

    return _in_memory_reports.get(report_id)


def list_reports(status: Optional[str] = None, severity: Optional[str] = None, limit: int = 100) -> List[dict]:
    if db is not None:
        try:
            query = db.collection(REPORTS).order_by("createdAt", direction="DESCENDING")
            if status:
                query = query.where("status", "==", status)
            if severity:
                query = query.where("severity", "==", severity)
            docs = query.limit(limit).stream()
            return [{"reportId": d.id, **d.to_dict()} for d in docs]
        except Exception:
            pass

    results = list(_in_memory_reports.values())
    if status:
        results = [r for r in results if r.get("status") == status]
    if severity:
        results = [r for r in results if r.get("severity") == severity]

    return results[:limit]


def update_report(report_id: str, updates: dict) -> None:
    now_iso = datetime.now(timezone.utc).isoformat()
    updates["updatedAt"] = now_iso

    if report_id in _in_memory_reports:
        _in_memory_reports[report_id].update(updates)

    if db is not None:
        try:
            db.collection(REPORTS).document(report_id).update({
                **updates,
                "updatedAt": datetime.now(timezone.utc),
            })
        except Exception:
            pass


def log_incident(report_id: str, action: str, performed_by: str, details: str = "") -> None:
    entry = {
        "reportId": report_id,
        "action": action,
        "performedBy": performed_by,
        "details": details,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }
    _in_memory_logs.append(entry)

    if db is not None:
        try:
            db.collection(LOGS).document().set({
                **entry,
                "timestamp": datetime.now(timezone.utc),
            })
        except Exception:
            pass


def create_notification(user_id: str, report_id: str, title: str, body: str) -> None:
    notif = {
        "userId": user_id,
        "reportId": report_id,
        "title": title,
        "body": body,
        "read": False,
        "createdAt": datetime.now(timezone.utc).isoformat(),
    }
    _in_memory_notifications.append(notif)

    if db is not None:
        try:
            db.collection(NOTIFICATIONS).document().set({
                **notif,
                "createdAt": datetime.now(timezone.utc),
            })
        except Exception:
            pass
