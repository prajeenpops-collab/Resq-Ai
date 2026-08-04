import uuid
from app.core.firebase import bucket


def upload_media(file_bytes: bytes, content_type: str, folder: str = "reports") -> str:
    """Uploads raw bytes to Firebase Storage and returns a public URL."""
    ext = content_type.split("/")[-1]
    blob_path = f"{folder}/{uuid.uuid4()}.{ext}"
    blob = bucket.blob(blob_path)
    blob.upload_from_string(file_bytes, content_type=content_type)
    blob.make_public()
    return blob.public_url
