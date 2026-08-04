from fastapi import Header, HTTPException, Depends
from firebase_admin import auth as firebase_auth
from app.core.firebase import db


async def get_current_user(authorization: str = Header(...)) -> dict:
    """
    Verifies the Firebase ID token sent as 'Authorization: Bearer <token>'.
    Returns the user's uid + role (fetched from Firestore users collection).
    """
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Invalid authorization header")

    token = authorization.split(" ", 1)[1]
    try:
        decoded = firebase_auth.verify_id_token(token)
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid or expired token")

    uid = decoded["uid"]
    user_doc = db.collection("users").document(uid).get()
    if not user_doc.exists:
        raise HTTPException(status_code=404, detail="User profile not found")

    user_data = user_doc.to_dict()
    return {"uid": uid, "role": user_data.get("role", "citizen"), **user_data}


def require_role(*allowed_roles: str):
    """Dependency factory for RBAC-restricted endpoints."""
    async def checker(user: dict = Depends(get_current_user)) -> dict:
        if user["role"] not in allowed_roles:
            raise HTTPException(status_code=403, detail="Insufficient permissions")
        return user
    return checker
