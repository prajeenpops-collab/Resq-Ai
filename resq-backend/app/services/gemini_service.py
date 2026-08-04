import json
import logging
import google.generativeai as genai
from app.core.config import get_settings

settings = get_settings()
genai.configure(api_key=settings.GEMINI_API_KEY)
logger = logging.getLogger("resq.gemini")

model = genai.GenerativeModel("gemini-2.0-flash")

SYSTEM_PROMPT = """You are ResQ AI, an advanced emergency triage & multi-agency intelligence assistant.
Analyze the emergency input (text, transcribed voice, and/or attached image) and respond with ONLY valid JSON, no markdown fences, no preamble, in this exact shape:

{
  "category": "medical" | "fire" | "accident" | "crime" | "natural_disaster" | "other",
  "severity": "critical" | "high" | "medium" | "low",
  "rootCause": "<identified primary root cause or origin of the incident, e.g., Structural Electrical Fire, High-Speed Collision, Toxic Gas Leak>",
  "departmentsToInform": ["<List of emergency agencies to inform, e.g., Fire Department (Suppression Unit), Hospital Trauma ER & ALS Ambulance (Burn Unit), Police (Perimeter Control)>"],
  "aiSummary": "<concise 2-sentence dispatcher summary incorporating root cause, severity, and agencies alerted>",
  "firstAidGuidance": "<step-by-step numbered safety & first-aid instructions tailored specifically to the incident and victims>"
}

Agency Selection Rules:
- If category is "fire": ALWAYS include "Fire Department (Suppression & Ladder Unit)". If casualties, burns, or smoke inhalation are mentioned/implied, ALWAYS include "Hospital Trauma ER & ALS Ambulance (Burn Unit)".
- If category is "medical": Include "Hospital Trauma ER" and "ALS Mobile ICU Ambulance".
- If category is "accident": Include "Fire Department (Extrication Rescue)", "ALS Ambulance", and "Traffic Police Patrol".
- If category is "natural_disaster": Include "Disaster Water Rescue Squad", "Fire Department", and "Emergency Management Agency".
- If category is "crime": Include "Police Tactical Patrol (SWAT)" and "Trauma Paramedics".
"""


async def analyze_emergency(
    raw_text: str | None,
    image_bytes: bytes | None = None,
    image_mime: str | None = None,
) -> dict:
    """
    Sends the report content to Gemini AI to extract category, severity, root cause, departmentsToInform, summary, and guidance.
    """
    parts = [SYSTEM_PROMPT]

    if raw_text:
        parts.append(f"\nCitizen emergency report text:\n{raw_text}")

    if image_bytes:
        parts.append({"mime_type": image_mime or "image/jpeg", "data": image_bytes})
        parts.append("\nAnalyze the attached image to identify the root cause, severity, and required emergency departments.")

    try:
        response = model.generate_content(parts)
        raw = response.text.strip()

        if raw.startswith("```"):
            raw = raw.strip("`")
            raw = raw.replace("json\n", "", 1) if raw.startswith("json\n") else raw

        result = json.loads(raw)

        if "departmentsToInform" not in result or not result["departmentsToInform"]:
            result["departmentsToInform"] = _infer_departments(result.get("category", "fire"), raw_text or "")

        if "rootCause" not in result:
            result["rootCause"] = _infer_root_cause(raw_text or "", result.get("category", "fire"))

        return result

    except (json.JSONDecodeError, ValueError) as e:
        logger.error(f"Gemini output parse failure: {e}")
        cat = _infer_category(raw_text or "")
        return {
            "category": cat,
            "severity": _infer_severity(raw_text or ""),
            "rootCause": _infer_root_cause(raw_text or "", cat),
            "departmentsToInform": _infer_departments(cat, raw_text or ""),
            "aiSummary": raw_text or "Emergency report received. Fire Department & Hospital alerted.",
            "firstAidGuidance": "1. Stay in a safe area upwind.\n2. Do not re-enter building.\n3. Await Fire Rescue and Ambulance.",
        }
    except Exception as e:
        logger.error(f"Gemini API call failed: {e}")
        cat = _infer_category(raw_text or "")
        return {
            "category": cat,
            "severity": _infer_severity(raw_text or ""),
            "rootCause": _infer_root_cause(raw_text or "", cat),
            "departmentsToInform": _infer_departments(cat, raw_text or ""),
            "aiSummary": raw_text or "Emergency report logged. Fire & Paramedics dispatched.",
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
    return "medical"


def _infer_severity(text: str) -> str:
    t = text.lower()
    if any(k in t for k in ["unconscious", "trapped", "bleeding", "explosion", "critical", "dying", "flame"]):
        return "critical"
    return "high"


def _infer_root_cause(text: str, category: str) -> str:
    t = text.lower()
    if "electrical" in t or "wire" in t:
        return "Electrical Circuit Ignition"
    if "gas" in t or "leak" in t:
        return "Pressurized Gas Line Rupture"
    if category == "fire":
        return "Structural Thermal Ignition & Smoke Hazard"
    return "Acute Emergency Incident"


def _infer_departments(category: str, text: str) -> list[str]:
    if category == "fire":
        return [
            "Fire Department (Suppression & Ladder Unit)",
            "Hospital Trauma ER & ALS Ambulance (Burn Unit)",
            "Police Patrol (Perimeter Security)",
        ]
    if category == "accident":
        return [
            "Fire Rescue (Extrication Unit)",
            "ALS Mobile ICU Ambulance",
            "Traffic Police Patrol",
        ]
    if category == "natural_disaster":
        return [
            "Disaster Water Rescue Squad",
            "Fire Department Emergency Unit",
            "Municipal Emergency Management",
        ]
    if category == "crime":
        return [
            "Police Tactical Unit (SWAT)",
            "Trauma Ambulance Paramedics",
        ]
    return [
        "Hospital Trauma ER Bay",
        "ALS Mobile ICU Ambulance",
    ]


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
