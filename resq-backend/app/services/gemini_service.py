import json
import logging
import google.generativeai as genai
from app.core.config import get_settings

settings = get_settings()
genai.configure(api_key=settings.GEMINI_API_KEY)
logger = logging.getLogger("resq.gemini")

model = genai.GenerativeModel("gemini-2.0-flash")

SYSTEM_PROMPT = """You are ResQ AI, an advanced emergency triage & intelligence assistant. Analyze the emergency input
(text, transcribed voice, and/or attached image) and respond with ONLY valid JSON, no markdown fences, no preamble, in this exact shape:

{
  "category": "medical" | "fire" | "accident" | "crime" | "natural_disaster" | "other",
  "severity": "critical" | "high" | "medium" | "low",
  "rootCause": "<identified primary root cause or origin of the incident, e.g., Electrical Short Circuit, High-Speed Collision, Gas Pipe Rupture, Flash Inundation, Violent Intrusion>",
  "aiSummary": "<concise 2-sentence dispatcher summary incorporating severity and root cause>",
  "firstAidGuidance": "<step-by-step numbered safety & first-aid instructions tailored specifically to the root cause and severity>"
}

Severity Classification Guide:
- critical: Immediate life-threatening emergency (unconscious victim, active structural fire with trapped occupants, severe arterial hemorrhage, active shooter)
- high: Serious emergency requiring rapid response (fractures, heavy smoke, multi-vehicle collision, active burglary)
- medium: Non-life-threatening incident (minor injury, contained small fire, past theft)
- low: Non-urgent inquiry or minor property issue
"""


async def analyze_emergency(
    raw_text: str | None,
    image_bytes: bytes | None = None,
    image_mime: str | None = None,
) -> dict:
    """
    Sends the report content to Gemini AI to extract category, severity, root cause, summary, and guidance.
    """
    parts = [SYSTEM_PROMPT]

    if raw_text:
        parts.append(f"\nCitizen emergency report text:\n{raw_text}")

    if image_bytes:
        parts.append({"mime_type": image_mime or "image/jpeg", "data": image_bytes})
        parts.append("\nAnalyze the attached image to identify the root cause and severity of the emergency.")

    try:
        response = model.generate_content(parts)
        raw = response.text.strip()

        if raw.startswith("```"):
            raw = raw.strip("`")
            raw = raw.replace("json\n", "", 1) if raw.startswith("json\n") else raw

        result = json.loads(raw)

        required_keys = {"category", "severity", "rootCause", "aiSummary", "firstAidGuidance"}
        if not required_keys.issubset(result.keys()):
            # Fill missing rootCause defensively
            if "rootCause" not in result:
                result["rootCause"] = _infer_root_cause(raw_text or "", result.get("category", "other"))
            if "category" not in result:
                result["category"] = "other"
            if "severity" not in result:
                result["severity"] = "high"

        return result

    except (json.JSONDecodeError, ValueError) as e:
        logger.error(f"Gemini output parse failure: {e}")
        return {
            "category": _infer_category(raw_text or ""),
            "severity": _infer_severity(raw_text or ""),
            "rootCause": _infer_root_cause(raw_text or "", "other"),
            "aiSummary": raw_text or "Emergency report received. Responders alerted.",
            "firstAidGuidance": "1. Stay in a safe area.\n2. Do not re-enter hazard zone.\n3. Await emergency responders.",
        }
    except Exception as e:
        logger.error(f"Gemini API call failed: {e}")
        return {
            "category": _infer_category(raw_text or ""),
            "severity": _infer_severity(raw_text or ""),
            "rootCause": _infer_root_cause(raw_text or "", "other"),
            "aiSummary": raw_text or "Emergency report logged. Response team dispatched.",
            "firstAidGuidance": "1. Keep emergency line open.\n2. Follow safety instructions from responders.",
        }


def _infer_category(text: str) -> str:
    t = text.lower()
    if any(k in t for k in ["fire", "smoke", "flame", "burn", "explosion"]):
        return "fire"
    if any(k in t for k in ["crash", "car", "accident", "vehicle", "collision"]):
        return "accident"
    if any(k in t for k in ["flood", "water", "storm", "rain", "landslide"]):
        return "natural_disaster"
    if any(k in t for k in ["gun", "shot", "thief", "attack", "robbery", "weapon"]):
        return "crime"
    if any(k in t for k in ["chemical", "gas", "leak", "fumes", "toxic", "poison"]):
        return "other"
    return "medical"


def _infer_severity(text: str) -> str:
    t = text.lower()
    if any(k in t for k in ["unconscious", "trapped", "bleeding", "explosion", "critical", "dying", "flame"]):
        return "critical"
    if any(k in t for k in ["crash", "fire", "injury", "broken", "severe"]):
        return "high"
    return "medium"


def _infer_root_cause(text: str, category: str) -> str:
    t = text.lower()
    if "electrical" in t or "wire" in t or "short" in t:
        return "Electrical Circuit Malfunction"
    if "gas" in t or "leak" in t:
        return "Pressurized Gas Line Rupture"
    if "speed" in t or "brake" in t or "skid" in t:
        return "High-Speed Vehicle Loss of Control"
    if "water" in t or "flood" in t:
        return "Heavy Precipitation Flash Inundation"

    defaults = {
        "fire": "Thermal Ignition / Electrical Spark",
        "accident": "Impact Kinetic Collision",
        "natural_disaster": "Severe Weather Disruption",
        "crime": "Unlawful Security Breach",
        "other": "Hazard Material Exposure",
    }
    return defaults.get(category, "Acute Medical Distress")


async def transcribe_audio(audio_bytes: bytes, mime_type: str = "audio/mp3") -> str:
    try:
        response = model.generate_content([
            "Transcribe this audio to plain text. Return ONLY the transcript, nothing else.",
            {"mime_type": mime_type, "data": audio_bytes},
        ])
        return response.text.strip()
    except Exception as e:
        logger.error(f"Gemini transcription failed: {e}")
        return ""
