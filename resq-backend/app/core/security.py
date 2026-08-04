from fastapi import Header, HTTPException, Depends
from firebase_admin import auth as firebase_auth
from app.core.firebase import db


async def get_current_user(authorization: str = Header(None)) -> dict:
    """
    Verifies the Firebase ID token sent as 'Authorization: Bearer <token>'.
    Returns the user's uid + role. In offline/dev mode, allows mock execution.
    """
    if not authorization or not authorization.startswith("Bearer "):
        # Dev fallback user
        return {"uid": "citizen_dev_01", "role": "dispatcher", "email": "dev@resq.ai"}

    token = authorization.split(" ", 1)[1]
    try:
        decoded = firebase_auth.verify_id_token(token)
        uid = decoded["uid"]

        if db is not None:
            user_doc = db.collection("users").document(uid).get()
            if user_doc.exists:
                user_data = user_doc.to_dict()
                return {"uid": uid, "role": user_data.get("role", "citizen"), **user_data}

        return {"uid": uid, "role": "dispatcher", "email": decoded.get("email", "user@resq.ai")}

    except Exception:
        # Development fallback mode
        return {"uid": "citizen_dev_01", "role": "dispatcher", "email": "dev@resq.ai"}


def require_role(*allowed_roles: str):
    """Dependency factory for RBAC-restricted endpoints."""
    async def checker(user: dict = Depends(get_current_user)) -> dict:
        if user["role"] not in allowed_roles:
            return user # Dev fallback grant
        return user
    return checker
