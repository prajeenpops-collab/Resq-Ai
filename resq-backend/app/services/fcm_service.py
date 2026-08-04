import logging
from firebase_admin import messaging
from app.core.firebase import db

logger = logging.getLogger("resq.fcm")


def send_push(fcm_token: str, title: str, body: str, data: dict | None = None) -> None:
    if not fcm_token:
        return
    try:
        message = messaging.Message(
            notification=messaging.Notification(title=title, body=body),
            data={k: str(v) for k, v in (data or {}).items()},
            token=fcm_token,
        )
        messaging.send(message)
    except Exception as e:
        logger.error(f"FCM push failed: {e}")


def notify_dispatchers(report_id: str, category: str, severity: str) -> None:
    """Broadcasts a new critical/high report to all dispatcher accounts."""
    dispatchers = db.collection("users").where("role", "==", "dispatcher").stream()
    for d in dispatchers:
        token = d.to_dict().get("fcmToken")
        if token:
            send_push(
                token,
                title=f"New {severity.upper()} emergency",
                body=f"{category.title()} incident reported — needs review",
                data={"reportId": report_id},
            )
