import json
import logging
import google.generativeai as genai
from app.core.config import get_settings

settings = get_settings()
genai.configure(api_key=settings.GEMINI_API_KEY)
logger = logging.getLogger("resq.gemini")

model = genai.GenerativeModel("gemini-2.0-flash")

SYSTEM_PROMPT = """You are ResQ AI, an emergency triage assistant. Analyze the input
(text, and/or transcribed voice, and/or image description) and respond with ONLY
valid JSON, no markdown fences, no preamble, in this exact shape:

{
  "category": "medical" | "fire" | "accident" | "crime" | "natural_disaster" | "other",
  "severity": "critical" | "high" | "medium" | "low",
  "aiSummary": "<one paragraph, factual, for a dispatcher to read in 5 seconds>",
  "firstAidGuidance": "<step-by-step numbered first-aid instructions the citizen can act on immediately while help is on the way. If not medical, give safety instructions instead.>"
}

Severity guide:
- critical: life-threatening, immediate response required (unconscious, not breathing, severe bleeding, active fire with people trapped)
- high: serious but stable-ish (broken bone, chest pain, moderate fire, active crime in progress)
- medium: needs response but not immediately life-threatening (minor injury, small contained fire, past crime)
- low: informational or minor (minor property damage, non-urgent request)
"""


async def analyze_emergency(
    raw_text: str | None,
    image_bytes: bytes | None = None,
    image_mime: str | None = None,
) -> dict:
    """
    Sends the report content to Gemini and returns structured triage data.
    raw_text: transcript (for voice) or typed text.
    image_bytes/mime: optional image attachment (Gemini handles vision natively).
    """
    parts = [SYSTEM_PROMPT]

    if raw_text:
        parts.append(f"\nCitizen report text:\n{raw_text}")

    if image_bytes:
        parts.append({"mime_type": image_mime or "image/jpeg", "data": image_bytes})
        parts.append("\nAnalyze the attached image as part of the emergency context.")

    try:
        response = model.generate_content(parts)
        raw = response.text.strip()

        # Defensive: strip markdown fences if Gemini adds them anyway
        if raw.startswith("```"):
            raw = raw.strip("`")
            raw = raw.replace("json\n", "", 1) if raw.startswith("json\n") else raw

        result = json.loads(raw)

        required_keys = {"category", "severity", "aiSummary", "firstAidGuidance"}
        if not required_keys.issubset(result.keys()):
            raise ValueError(f"Gemini response missing keys: {required_keys - result.keys()}")

        return result

    except (json.JSONDecodeError, ValueError) as e:
        logger.error(f"Gemini output parse failure: {e}")
        # Fail-safe: never drop a report silently, flag for manual dispatcher review
        return {
            "category": "other",
            "severity": "high",
            "aiSummary": raw_text or "Unable to auto-analyze — requires manual review.",
            "firstAidGuidance": "AI analysis failed. A dispatcher will review this report manually.",
        }
    except Exception as e:
        logger.error(f"Gemini API call failed: {e}")
        return {
            "category": "other",
            "severity": "high",
            "aiSummary": raw_text or "Unable to auto-analyze — requires manual review.",
            "firstAidGuidance": "AI analysis failed. A dispatcher will review this report manually.",
        }


async def transcribe_audio(audio_bytes: bytes, mime_type: str = "audio/mp3") -> str:
    """Gemini also handles audio input natively — used for voice reports."""
    try:
        response = model.generate_content([
            "Transcribe this audio to plain text. Return ONLY the transcript, nothing else.",
            {"mime_type": mime_type, "data": audio_bytes},
        ])
        return response.text.strip()
    except Exception as e:
        logger.error(f"Gemini transcription failed: {e}")
        return ""
