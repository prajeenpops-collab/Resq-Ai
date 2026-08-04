from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
import os

from app.api.v1.router import api_router
from app.utils.logger import setup_logging
from app.utils.exceptions import unhandled_exception_handler

setup_logging()

app = FastAPI(
    title="ResQ AI",
    description="Intelligent Emergency Response & Rescue Platform API",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],   # tighten to dashboard domain before production
    allow_methods=["*"],
    allow_headers=["*"],
)

app.add_exception_handler(Exception, unhandled_exception_handler)
app.include_router(api_router)

static_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "static")
if os.path.exists(static_dir):
    app.mount("/static", StaticFiles(directory=static_dir), name="static")


@app.get("/dashboard")
async def get_dashboard():
    dashboard_path = os.path.join(static_dir, "dashboard.html")
    if os.path.exists(dashboard_path):
        return FileResponse(dashboard_path)
    return {"error": "Dashboard HTML not found"}


@app.get("/health")
async def health():
    return {"status": "ok", "service": "ResQ AI Backend"}

