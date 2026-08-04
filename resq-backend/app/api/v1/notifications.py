from fastapi import APIRouter, Depends
from app.core.security import get_current_user
from app.core.firebase import db

router = APIRouter(prefix="/notifications", tags=["notifications"])


@router.get("/mine")
async def my_notifications(user: dict = Depends(get_current_user)):
    docs = (
        db.collection("notifications")
        .where("userId", "==", user["uid"])
        .order_by("createdAt", direction="DESCENDING")
        .limit(50)
        .stream()
    )
    return [{"id": d.id, **d.to_dict()} for d in docs]


@router.patch("/{notif_id}/read")
async def mark_read(notif_id: str, user: dict = Depends(get_current_user)):
    db.collection("notifications").document(notif_id).update({"read": True})
    return {"id": notif_id, "read": True}
