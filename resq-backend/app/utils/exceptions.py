import logging
from fastapi import Request
from fastapi.responses import JSONResponse

logger = logging.getLogger("resq.exceptions")


async def unhandled_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    logger.error(f"Unhandled error on {request.url.path}: {exc}")
    return JSONResponse(
        status_code=500,
        content={"detail": "Internal server error. The incident has been logged."},
    )
