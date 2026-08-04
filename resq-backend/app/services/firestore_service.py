from datetime import datetime, timezone
from google.cloud.firestore_v1 import GeoPoint
from app.core.firebase import db

REPORTS = "emergency_reports"
NOTIFICATIONS = "notifications"
LOGS = "incident_logs"


def create_report(data: dict) -> str:
    doc_ref = db.collection(REPORTS).document()
    now = datetime.now(timezone.utc)
    payload = {
        **data,
        "location": GeoPoint(data["location"]["lat"], data["location"]["lng"]),
        "status": "pending",
        "assignedResources": [],
        "createdAt": now,
        "updatedAt": now,
    }
    doc_ref.set(payload)
    return doc_ref.id


def get_report(report_id: str) -> dict | None:
    doc = db.collection(REPORTS).document(report_id).get()
    if not doc.exists:
        return None
    return {"reportId": doc.id, **doc.to_dict()}


def list_reports(status: str | None = None, severity: str | None = None, limit: int = 100) -> list[dict]:
    query = db.collection(REPORTS).order_by("createdAt", direction="DESCENDING")
    if status:
        query = query.where("status", "==", status)
    if severity:
        query = query.where("severity", "==", severity)
    docs = query.limit(limit).stream()
    return [{"reportId": d.id, **d.to_dict()} for d in docs]


def update_report(report_id: str, updates: dict) -> None:
    updates["updatedAt"] = datetime.now(timezone.utc)
    db.collection(REPORTS).document(report_id).update(updates)


def log_incident(report_id: str, action: str, performed_by: str, details: str = "") -> None:
    db.collection(LOGS).document().set({
        "reportId": report_id,
        "action": action,
        "performedBy": performed_by,
        "details": details,
        "timestamp": datetime.now(timezone.utc),
    })


def create_notification(user_id: str, report_id: str, title: str, body: str) -> None:
    db.collection(NOTIFICATIONS).document().set({
        "userId": user_id,
        "reportId": report_id,
        "title": title,
        "body": body,
        "read": False,
        "createdAt": datetime.now(timezone.utc),
    })
