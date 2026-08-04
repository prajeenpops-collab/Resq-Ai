import os
import firebase_admin
from firebase_admin import credentials, firestore, storage
from app.core.config import get_settings

settings = get_settings()

if not firebase_admin._apps:
    cred_path = settings.FIREBASE_CREDENTIALS_PATH
    if os.path.exists(cred_path):
        _cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(_cred, {
            "storageBucket": settings.FIREBASE_STORAGE_BUCKET
        })
    else:
        # Development / Fallback mode
        firebase_admin.initialize_app(options={
            "storageBucket": settings.FIREBASE_STORAGE_BUCKET
        })

try:
    db = firestore.client()
except Exception:
    db = None

try:
    bucket = storage.bucket()
except Exception:
    bucket = None

