from fastapi import APIRouter
from app.api.v1 import emergency, dashboard, assignment, notifications, protocols

api_router = APIRouter(prefix="/api/v1")
api_router.include_router(emergency.router)
api_router.include_router(dashboard.router)
api_router.include_router(assignment.router)
api_router.include_router(notifications.router)
api_router.include_router(protocols.router)

