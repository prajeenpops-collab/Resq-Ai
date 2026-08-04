import firebase_admin
from firebase_admin import credentials, firestore, storage
from app.core.config import get_settings

settings = get_settings()

_cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
firebase_admin.initialize_app(_cred, {
    "storageBucket": settings.FIREBASE_STORAGE_BUCKET
})

db = firestore.client()
bucket = storage.bucket()
