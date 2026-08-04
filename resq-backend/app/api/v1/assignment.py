from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import Literal

from app.core.security import require_role, get_current_user
from app.core.firebase import db
from app.services import firestore_service, fcm_service

router = APIRouter(prefix="/assignment", tags=["assignment"])

RESOURCE_COLLECTIONS = {
    "ambulance": "ambulances",
    "police": "police_units",
    "fire": "fire_stations",
    "hospital": "hospitals",
}


class AssignRequest(BaseModel):
    reportId: str
    resourceType: Literal["ambulance", "police", "fire", "hospital"]
    resourceId: str


@router.post("/assign")
async def assign_resource(payload: AssignRequest, user: dict = Depends(require_role("dispatcher"))):
    collection = RESOURCE_COLLECTIONS[payload.resourceType]
    resource_ref = db.collection(collection).document(payload.resourceId)
    resource_doc = resource_ref.get()

    if not resource_doc.exists:
        raise HTTPException(status_code=404, detail="Resource not found")
    if resource_doc.to_dict().get("status") != "available":
        raise HTTPException(status_code=409, detail="Resource is not available")

    report = firestore_service.get_report(payload.reportId)
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")

    resource_ref.update({"status": "busy", "assignedReportId": payload.reportId})

    assigned = report.get("assignedResources", [])
    assigned.append({"type": payload.resourceType, "resourceId": payload.resourceId})
    firestore_service.update_report(payload.reportId, {
        "assignedResources": assigned,
        "status": "assigned",
    })

    firestore_service.log_incident(
        payload.reportId, "resource_assigned", user["uid"],
        f"{payload.resourceType}:{payload.resourceId}"
    )

    reporter_id = report.get("userId")
    if reporter_id:
        firestore_service.create_notification(
            reporter_id, payload.reportId,
            title="Help is on the way",
            body=f"A {payload.resourceType} has been dispatched to your location.",
        )

    return {"reportId": payload.reportId, "assignedResource": payload.resourceId, "status": "assigned"}
