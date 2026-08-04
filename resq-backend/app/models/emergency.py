from pydantic import BaseModel, Field
from typing import Optional, List, Literal
from datetime import datetime


class Location(BaseModel):
    lat: float
    lng: float


class AssignedResource(BaseModel):
    type: Literal["ambulance", "police", "fire", "hospital"]
    resourceId: str
    assignedAt: Optional[datetime] = None


class EmergencyReportCreate(BaseModel):
    """Payload sent by the citizen mobile app when submitting a report."""
    type: Literal["voice", "text", "image"]
    rawText: Optional[str] = None          # typed text, or filled after transcription
    mediaUrl: Optional[str] = None          # Storage URL for voice/image, uploaded client-side first
    location: Location
    address: Optional[str] = None


class EmergencyReportResponse(BaseModel):
    """What we return after AI processing — shown immediately to the citizen."""
    reportId: str
    category: str
    severity: str
    aiSummary: str
    firstAidGuidance: str
    status: str
    createdAt: datetime


class EmergencyReportUpdate(BaseModel):
    status: Optional[Literal["pending", "assigned", "in_progress", "resolved", "cancelled"]] = None
    assignedResources: Optional[List[AssignedResource]] = None


class EmergencyReportFull(BaseModel):
    """Full document shape — used by dashboard feed."""
    reportId: str
    userId: str
    type: str
    rawText: Optional[str]
    mediaUrl: Optional[str]
    aiSummary: str
    category: str
    severity: str
    location: Location
    address: Optional[str]
    status: str
    assignedResources: List[AssignedResource] = []
    firstAidGuidance: str
    createdAt: datetime
    updatedAt: datetime
