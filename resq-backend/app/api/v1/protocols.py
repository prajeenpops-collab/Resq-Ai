from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import Optional, Dict, Any, List

from app.core.security import get_current_user
from app.services import protocol_service

router = APIRouter(prefix="/protocols", tags=["protocols"])


class ExecuteProtocolRequest(BaseModel):
    reportId: str
    protocolId: Optional[str] = None


class AiGenerateProtocolRequest(BaseModel):
    rawText: str
    category: Optional[str] = "other"
    severity: Optional[str] = "high"


@router.get("", response_model=List[Dict[str, Any]])
async def list_protocols(user: dict = Depends(get_current_user)):
    """Retrieve all standard emergency response protocols."""
    return protocol_service.get_all_protocols()


@router.get("/{protocol_id}", response_model=Dict[str, Any])
async def get_protocol_detail(protocol_id: str, user: dict = Depends(get_current_user)):
    """Retrieve details & safety checklist for a specific protocol."""
    proto = protocol_service.get_protocol(protocol_id)
    if not proto:
        raise HTTPException(status_code=404, detail="Emergency Protocol not found")
    return proto


@router.post("/execute", response_model=Dict[str, Any])
async def trigger_protocol_execution(
    payload: ExecuteProtocolRequest,
    user: dict = Depends(get_current_user),
):
    """
    Automated Engine Trigger:
    Automatically executes the matched/selected protocol workflow for an active emergency report.
    Dispatches units, notifies emergency contacts, logs incident timeline, and streams step telemetry.
    """
    try:
        execution = protocol_service.execute_protocol(
            report_id=payload.reportId,
            protocol_id=payload.protocolId,
        )
        return execution
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc))
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Failed to execute protocol: {exc}")


@router.get("/active/{report_id}", response_model=Dict[str, Any])
async def get_active_protocol_telemetry(
    report_id: str,
    user: dict = Depends(get_current_user),
):
    """Retrieve active automated protocol execution state and progress for a report."""
    execution = protocol_service.get_active_execution(report_id)
    if not execution:
        raise HTTPException(status_code=404, detail="No active protocol found for this report")
    return execution


class AdvanceStepRequest(BaseModel):
    reportId: str
    targetStepIndex: Optional[int] = None


@router.post("/advance-step", response_model=Dict[str, Any])
async def advance_step(
    payload: AdvanceStepRequest,
    user: dict = Depends(get_current_user),
):
    """Allows dispatchers to manually advance protocol steps from the Web Command Center."""
    try:
        return protocol_service.advance_protocol_step(
            report_id=payload.reportId,
            target_step_index=payload.targetStepIndex,
        )
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc))


@router.post("/ai-generate", response_model=Dict[str, Any])
async def generate_ai_protocol(
    payload: AiGenerateProtocolRequest,
    user: dict = Depends(get_current_user),
):
    """Use Gemini AI to dynamically generate a custom emergency protocol on the fly."""
    result = await protocol_service.generate_ai_custom_protocol({
        "rawText": payload.rawText,
        "category": payload.category,
        "severity": payload.severity,
    })
    return result

