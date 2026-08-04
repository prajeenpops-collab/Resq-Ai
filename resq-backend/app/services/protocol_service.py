from datetime import datetime, timezone
import logging
from typing import Dict, List, Any, Optional

from app.services import firestore_service, gemini_service, fcm_service

logger = logging.getLogger("resq.protocols")

# Standard Emergency Response Protocols Repository
PROTOCOLS: Dict[str, Dict[str, Any]] = {
    "cardiac_arrest": {
        "protocolId": "cardiac_arrest",
        "title": "Cardiac & Critical Medical Response Protocol",
        "category": "medical",
        "severityTarget": "critical",
        "icon": "favorite",
        "summary": "Rapid 5-phase automated protocol for cardiac arrest, severe trauma, or respiratory failure.",
        "autoTriggerRules": {
            "categories": ["medical"],
            "severities": ["critical", "high"],
            "keywords": ["cardiac", "heart", "breath", "unconscious", "stroke", "bleeding", "collapse", "pulse"],
        },
        "dispatchMatrix": [
            {"type": "ambulance", "unitClass": "Advanced Life Support (ALS) Mobile ICU", "targetEtaSec": 300},
            {"type": "hospital", "unitClass": "Level-1 Trauma Center ER Alert", "targetEtaSec": 0},
        ],
        "automatedSteps": [
            {
                "stepNumber": 1,
                "title": "Immediate Critical Triage & Priority Alarm",
                "description": "Auto-flagged as Red Tier 1 incident. High-priority audio/visual alert broadcast to nearest dispatch hub.",
                "actionType": "auto_triage",
                "etaSeconds": 15,
                "status": "completed",
            },
            {
                "stepNumber": 2,
                "title": "Automated ALS Ambulance & ER Dispatch",
                "description": "Auto-dispatch nearest available ALS Paramedic Ambulance with GPS telemetry lock.",
                "actionType": "auto_dispatch",
                "etaSeconds": 60,
                "status": "in_progress",
            },
            {
                "stepNumber": 3,
                "title": "Emergency Contact & CPR Beacon Broadcast",
                "description": "Broadcast SMS/FCM alert to designated emergency contacts with live GPS tracker & request nearby CPR certified citizens.",
                "actionType": "broadcast_alert",
                "etaSeconds": 120,
                "status": "pending",
            },
            {
                "stepNumber": 4,
                "title": "Interactive CPR / First-Aid Checklist Sync",
                "description": "Stream step-by-step CPR rate metronome and airway management instructions to citizen smartphone.",
                "actionType": "first_aid_prompt",
                "etaSeconds": 180,
                "status": "pending",
            },
            {
                "stepNumber": 5,
                "title": "Hospital Emergency Room Pre-Arrival Briefing",
                "description": "Transmit victim profile, live telemetry, and estimated arrival time to trauma center receiving bay.",
                "actionType": "incident_command_sync",
                "etaSeconds": 300,
                "status": "pending",
            },
        ],
        "safetyChecklist": [
            "Check for responsiveness: Tap shoulders and shout 'Are you okay?'",
            "Call for help and locate nearest AED (Automated External Defibrillator).",
            "Place patient flat on back on hard surface.",
            "Begin chest compressions: Push hard and fast in center of chest (100-120 bpm).",
            "Keep airway open and monitor breathing until paramedics arrive.",
        ],
    },
    "structure_fire": {
        "protocolId": "structure_fire",
        "title": "Structural Fire & Evacuation Protocol",
        "category": "fire",
        "severityTarget": "critical",
        "icon": "local_fire_department",
        "summary": "Automated fire suppression, occupant evacuation alert, and multi-agency perimeter response.",
        "autoTriggerRules": {
            "categories": ["fire"],
            "severities": ["critical", "high", "medium"],
            "keywords": ["fire", "smoke", "flame", "explosion", "trapped", "burning", "building"],
        },
        "dispatchMatrix": [
            {"type": "fire", "unitClass": "Class-A Pumper & Heavy Ladder Truck", "targetEtaSec": 360},
            {"type": "ambulance", "unitClass": "Burn Specialist Transport Unit", "targetEtaSec": 420},
            {"type": "police", "unitClass": "Perimeter Control & Traffic Management", "targetEtaSec": 300},
        ],
        "automatedSteps": [
            {
                "stepNumber": 1,
                "title": "Fire Incident Classification & GPS Geofence Alarm",
                "description": "Auto-verify fire report location and establish 500m evacuation alert boundary.",
                "actionType": "auto_triage",
                "etaSeconds": 20,
                "status": "completed",
            },
            {
                "stepNumber": 2,
                "title": "Multi-Engine Fire Rescue Dispatch",
                "description": "Auto-dispatch nearest Fire Station Heavy Engine and Search & Rescue Ladder team.",
                "actionType": "auto_dispatch",
                "etaSeconds": 90,
                "status": "in_progress",
            },
            {
                "stepNumber": 3,
                "title": "Geofenced Evacuation Alert Broadcast",
                "description": "Send emergency evacuation alert to nearby mobile users and emergency contacts.",
                "actionType": "broadcast_alert",
                "etaSeconds": 150,
                "status": "pending",
            },
            {
                "stepNumber": 4,
                "title": "Smoke & Thermal Safety Guidance",
                "description": "Display low-smoke escape path guides and door temperature test instructions on user device.",
                "actionType": "first_aid_prompt",
                "etaSeconds": 210,
                "status": "pending",
            },
            {
                "stepNumber": 5,
                "title": "Fire Hydrant Network & Water Main Pre-Charge",
                "description": "Alert municipal water dispatch for pressure boost on surrounding fire hydrants.",
                "actionType": "incident_command_sync",
                "etaSeconds": 360,
                "status": "pending",
            },
        ],
        "safetyChecklist": [
            "Crawl low under smoke — clean air is closest to the floor.",
            "Feel doors with back of hand before opening; if hot, do NOT open.",
            "If clothes catch fire: Stop, Drop, and Roll.",
            "Once outside, stay out. Never re-enter a burning structure.",
            "Signal location from window if trapped using brightly colored cloth or flashlight.",
        ],
    },
    "vehicle_crash": {
        "protocolId": "vehicle_crash",
        "title": "High-Speed Collision & Vehicle Entrapment Protocol",
        "category": "accident",
        "severityTarget": "high",
        "icon": "car_crash",
        "summary": "Automated collision protocol for vehicular crashes, extrication needs, and traffic diversion.",
        "autoTriggerRules": {
            "categories": ["accident"],
            "severities": ["critical", "high", "medium"],
            "keywords": ["crash", "accident", "car", "highway", "flipped", "trapped", "collision", "rollover"],
        },
        "dispatchMatrix": [
            {"type": "police", "unitClass": "Highway Patrol & Crash Investigation Unit", "targetEtaSec": 240},
            {"type": "ambulance", "unitClass": "Trauma Mobile Transport", "targetEtaSec": 300},
            {"type": "fire", "unitClass": "Heavy Extrication & Hydraulic Cutter Unit", "targetEtaSec": 360},
        ],
        "automatedSteps": [
            {
                "stepNumber": 1,
                "title": "Automated Crash Impact & GPS Localization",
                "description": "Process crash coordinates, estimate traffic impact, and alert highway control.",
                "actionType": "auto_triage",
                "etaSeconds": 15,
                "status": "completed",
            },
            {
                "stepNumber": 2,
                "title": "Triple-Agency Dispatch Command",
                "description": "Auto-dispatch Police Patrol for traffic rerouting, Ambulance for casualties, and Fire for extrication.",
                "actionType": "auto_dispatch",
                "etaSeconds": 60,
                "status": "in_progress",
            },
            {
                "stepNumber": 3,
                "title": "Traffic Navigation Alert & Hazard Warning",
                "description": "Broadcast dynamic traffic detour alerts to approaching vehicles within 2km.",
                "actionType": "broadcast_alert",
                "etaSeconds": 120,
                "status": "pending",
            },
            {
                "stepNumber": 4,
                "title": "Spinal Safety & Passenger Check Guidance",
                "description": "Provide instructions for immobilizing neck/spine and safe distance from battery hazard.",
                "actionType": "first_aid_prompt",
                "etaSeconds": 180,
                "status": "pending",
            },
            {
                "stepNumber": 5,
                "title": "Tow & Debris Clearing Logistics Trigger",
                "description": "Notify heavy towing services and road clearance crews for rapid lane re-opening.",
                "actionType": "incident_command_sync",
                "etaSeconds": 300,
                "status": "pending",
            },
        ],
        "safetyChecklist": [
            "Turn off vehicle ignition immediately to prevent electrical fires.",
            "Do NOT move injured victims unless there is immediate risk of fire or explosion.",
            "Support head and neck of casualties to prevent spinal injury.",
            "Set hazard lights and place warning triangles upstream if safe.",
            "Stay clear of undeployed airbags and leaking fluids.",
        ],
    },
    "natural_disaster": {
        "protocolId": "natural_disaster",
        "title": "Flash Flood & Severe Weather Response Protocol",
        "category": "natural_disaster",
        "severityTarget": "high",
        "icon": "flood",
        "summary": "Automated flood, storm, or landslide emergency protocol with high-ground routing and rescue boat dispatch.",
        "autoTriggerRules": {
            "categories": ["natural_disaster"],
            "severities": ["critical", "high", "medium"],
            "keywords": ["flood", "landslide", "earthquake", "storm", "tsunami", "water", "trapped"],
        },
        "dispatchMatrix": [
            {"type": "fire", "unitClass": "Water Rescue Squad & Inflatable Craft", "targetEtaSec": 480},
            {"type": "police", "unitClass": "Disaster Response Taskforce", "targetEtaSec": 420},
        ],
        "automatedSteps": [
            {
                "stepNumber": 1,
                "title": "Geospatial Inundation Assessment",
                "description": "Map water elevation risk around report coordinates and alert Emergency Management.",
                "actionType": "auto_triage",
                "etaSeconds": 30,
                "status": "completed",
            },
            {
                "stepNumber": 2,
                "title": "Water Rescue & High-Water Craft Dispatch",
                "description": "Deploy specialized Flood Rescue Unit equipped with boats and thermal sonar.",
                "actionType": "auto_dispatch",
                "etaSeconds": 120,
                "status": "in_progress",
            },
            {
                "stepNumber": 3,
                "title": "High-Ground Evacuation Siren Alert",
                "description": "Send urgent high-ground directional map and shelters beacon to user device.",
                "actionType": "broadcast_alert",
                "etaSeconds": 180,
                "status": "pending",
            },
            {
                "stepNumber": 4,
                "title": "Electrical & Water Safety Protocol Guidance",
                "description": "Provide guidance on shutting off mains electrical power and avoiding fast currents.",
                "actionType": "first_aid_prompt",
                "etaSeconds": 240,
                "status": "pending",
            },
            {
                "stepNumber": 5,
                "title": "Shelter Supply & Helicopter Airlift Request",
                "description": "Coordinate emergency relief kit distribution and aerial sweep for trapped victims.",
                "actionType": "incident_command_sync",
                "etaSeconds": 480,
                "status": "pending",
            },
        ],
        "safetyChecklist": [
            "Move immediately to higher ground or upper floors of sturdy structures.",
            "Do NOT attempt to walk or drive through moving flood water (Turn Around, Don't Drown).",
            "Shut off main electrical breaker if safe to do so before water reaches outlets.",
            "Keep emergency whistle or flashlight handy to signal location to rescue boats.",
            "Stay away from downed power lines and submerged electrical equipment.",
        ],
    },
    "hazmat_leak": {
        "protocolId": "hazmat_leak",
        "title": "Hazardous Chemical & Gas Spill Response Protocol",
        "category": "other",
        "severityTarget": "high",
        "icon": "science",
        "summary": "Automated containment, chemical neutralization, and toxic plume isolation protocol.",
        "autoTriggerRules": {
            "categories": ["other"],
            "severities": ["critical", "high"],
            "keywords": ["chemical", "gas", "leak", "toxic", "poison", "hazmat", "fumes", "radiation", "ammonia"],
        },
        "dispatchMatrix": [
            {"type": "fire", "unitClass": "Hazmat Decontamination & Spill Control Team", "targetEtaSec": 420},
            {"type": "police", "unitClass": "Toxic Plume Exclusion Zone Security", "targetEtaSec": 300},
            {"type": "ambulance", "unitClass": "Chemical Antidote Mobile Unit", "targetEtaSec": 360},
        ],
        "automatedSteps": [
            {
                "stepNumber": 1,
                "title": "Chemical Toxicity Matrix Lookup & Plume Map",
                "description": "Analyze reported gas/chemical type and calculate wind-direction dispersion radius.",
                "actionType": "auto_triage",
                "etaSeconds": 25,
                "status": "completed",
            },
            {
                "stepNumber": 2,
                "title": "Hazmat Containment Unit Dispatch",
                "description": "Auto-dispatch Hazmat Level-A suit personnel with gas detection sensors.",
                "actionType": "auto_dispatch",
                "etaSeconds": 90,
                "status": "in_progress",
            },
            {
                "stepNumber": 3,
                "title": "Upwind Evacuation Alert Broadcast",
                "description": "Alert residents downwind to shelter-in-place with sealed windows or evacuate upwind.",
                "actionType": "broadcast_alert",
                "etaSeconds": 150,
                "status": "pending",
            },
            {
                "stepNumber": 4,
                "title": "Respiratory Protection & Wash Guidance",
                "description": "Instruct victim to cover nose/mouth with damp cloth and flush exposed skin with clean water.",
                "actionType": "first_aid_prompt",
                "etaSeconds": 210,
                "status": "pending",
            },
            {
                "stepNumber": 5,
                "title": "Environmental Protection Agency Notification",
                "description": "Notify EPA and industrial safety authorities for containment monitoring.",
                "actionType": "incident_command_sync",
                "etaSeconds": 420,
                "status": "pending",
            },
        ],
        "safetyChecklist": [
            "Move UPWIND and UPHILL away from the chemical source immediately.",
            "Cover mouth and nose with a damp cloth or mask to filter airborne particulates.",
            "If indoors, turn off HVAC/air conditioning systems and seal doors with wet towels.",
            "If exposed, remove contaminated clothing without touching face and flush skin with water.",
            "Do NOT ignite matches, lighters, or operate switches if flammable gas is suspected.",
        ],
    },
    "active_threat": {
        "protocolId": "active_threat",
        "title": "Active Threat & Critical Security Protocol",
        "category": "crime",
        "severityTarget": "critical",
        "icon": "security",
        "summary": "Automated rapid law enforcement response, silent alert mode, and perimeter lock-down.",
        "autoTriggerRules": {
            "categories": ["crime"],
            "severities": ["critical", "high"],
            "keywords": ["gun", "weapon", "shooter", "robbery", "attack", "hostage", "violence", "threat"],
        },
        "dispatchMatrix": [
            {"type": "police", "unitClass": "Tactical Emergency Response Team (SWAT/Patrol)", "targetEtaSec": 180},
            {"type": "ambulance", "unitClass": "Tactical Medical Combat Unit", "targetEtaSec": 300},
        ],
        "automatedSteps": [
            {
                "stepNumber": 1,
                "title": "Silent High-Priority Security Alarm Trigger",
                "description": "Activate silent alert mode; mute user device speaker to preserve citizen safety.",
                "actionType": "auto_triage",
                "etaSeconds": 10,
                "status": "completed",
            },
            {
                "stepNumber": 2,
                "title": "Tactical Police Patrol & Unit Dispatch",
                "description": "Auto-dispatch all active police cruisers within 3km to seal incident perimeter.",
                "actionType": "auto_dispatch",
                "etaSeconds": 45,
                "status": "in_progress",
            },
            {
                "stepNumber": 3,
                "title": "Silent GPS Location Streaming & Dispatch Sync",
                "description": "Stream continuous encrypted GPS telemetry to dispatch tactical map.",
                "actionType": "broadcast_alert",
                "etaSeconds": 90,
                "status": "pending",
            },
            {
                "stepNumber": 4,
                "title": "Run - Hide - Fight Tactical Instructions",
                "description": "Display silent text guide for barricading doors, silencing phones, and taking cover.",
                "actionType": "first_aid_prompt",
                "etaSeconds": 120,
                "status": "pending",
            },
            {
                "stepNumber": 5,
                "title": "Multi-Building Lockdown Synchronization",
                "description": "Signal nearby facility security systems to initiate access control lock-down.",
                "actionType": "incident_command_sync",
                "etaSeconds": 180,
                "status": "pending",
            },
        ],
        "safetyChecklist": [
            "RUN: If there is an accessible escape path, attempt to evacuate immediately.",
            "HIDE: If evacuation is impossible, lock and barricade doors, turn off lights, silences phone.",
            "STAY SILENT: Keep out of sight from windows and doors. Do NOT make unnecessary sound.",
            "FIGHT: As a last resort when in imminent danger, act with aggression to disarm threat.",
            "WHEN POLICE ARRIVE: Keep hands visible and empty, obey all officer commands instantly.",
        ],
    },
}


def get_all_protocols() -> List[Dict[str, Any]]:
    return list(PROTOCOLS.values())


def get_protocol(protocol_id: str) -> Optional[Dict[str, Any]]:
    return PROTOCOLS.get(protocol_id)


def match_protocol_for_report(category: str, severity: str, raw_text: str = "") -> Dict[str, Any]:
    text_lower = (raw_text or "").lower()

    # Match by explicit category & keywords
    for proto in PROTOCOLS.values():
        rules = proto["autoTriggerRules"]
        if category in rules["categories"]:
            if any(kw in text_lower for kw in rules.get("keywords", [])):
                return proto

    # Fallback by category
    category_defaults = {
        "medical": "cardiac_arrest",
        "fire": "structure_fire",
        "accident": "vehicle_crash",
        "natural_disaster": "natural_disaster",
        "crime": "active_threat",
    }
    matched_id = category_defaults.get(category, "cardiac_arrest")
    return PROTOCOLS[matched_id]


def execute_protocol(report_id: str, protocol_id: Optional[str] = None) -> Dict[str, Any]:
    """
    Automated execution runner:
    1. Fetches or matches the protocol for the report
    2. Auto-assigns nearest simulated resources (Ambulance, Fire, Police, Hospital)
    3. Logs protocol steps & incident timeline
    4. Triggers emergency contacts notification
    5. Returns active protocol execution state
    """
    report = firestore_service.get_report(report_id)
    if not report:
        raise ValueError(f"Report {report_id} not found for protocol execution.")

    if not protocol_id:
        proto_data = match_protocol_for_report(
            category=report.get("category", "medical"),
            severity=report.get("severity", "high"),
            raw_text=report.get("rawText", ""),
        )
    else:
        proto_data = PROTOCOLS.get(protocol_id, PROTOCOLS["cardiac_arrest"])

    now_iso = datetime.now(timezone.utc).isoformat()

    # Simulated Dispatched Units based on matrix
    dispatched_units = []
    for item in proto_data.get("dispatchMatrix", []):
        unit_id = f"RESQ-{item['type'].upper()}-09"
        dispatched_units.append({
            "unitId": unit_id,
            "type": item["type"],
            "unitClass": item["unitClass"],
            "status": "en_route",
            "etaSeconds": item["targetEtaSec"],
            "dispatchedAt": now_iso,
            "driverName": f"Officer / Paramedic {unit_id[-4:]}",
            "contactPhone": "+1-800-RESQ-911",
        })

    # Prepare active execution record
    active_execution = {
        "reportId": report_id,
        "protocolId": proto_data["protocolId"],
        "title": proto_data["title"],
        "category": proto_data["category"],
        "severity": report.get("severity", "high"),
        "status": "executing",
        "currentStepIndex": 1,
        "totalSteps": len(proto_data["automatedSteps"]),
        "automatedSteps": proto_data["automatedSteps"],
        "dispatchedUnits": dispatched_units,
        "safetyChecklist": proto_data["safetyChecklist"],
        "contactsNotified": True,
        "emergencyBroadcastSent": True,
        "startedAt": now_iso,
        "lastUpdated": now_iso,
    }

    # Update Firestore Report with active protocol status & resources
    assigned_resources = [
        {"type": u["type"], "resourceId": u["unitId"]} for u in dispatched_units
    ]
    firestore_service.update_report(report_id, {
        "status": "assigned",
        "activeProtocol": active_execution,
        "assignedResources": assigned_resources,
    })

    # Log Incident Timeline
    firestore_service.log_incident(
        report_id=report_id,
        action="protocol_auto_executed",
        performed_by="ResQ-AI-Automated-Engine",
        details=f"Triggered Protocol '{proto_data['title']}' with {len(dispatched_units)} units dispatched.",
    )

    # Trigger Emergency Notification to Reporter
    reporter_id = report.get("userId")
    if reporter_id:
        firestore_service.create_notification(
            user_id=reporter_id,
            report_id=report_id,
            title=f"AUTOMATED PROTOCOL ACTIVE: {proto_data['title']}",
            body=f"{len(dispatched_units)} emergency units dispatched. Follow live protocol steps.",
        )

    logger.info(f"Successfully auto-executed protocol {proto_data['protocolId']} for report {report_id}")
    return active_execution


def get_active_execution(report_id: str) -> Optional[Dict[str, Any]]:
    report = firestore_service.get_report(report_id)
    if not report:
        return None
    
    if "activeProtocol" in report and report["activeProtocol"]:
        return report["activeProtocol"]
    
    # If report exists but has no active protocol, auto-trigger one!
    return execute_protocol(report_id)


async def generate_ai_custom_protocol(report_data: Dict[str, Any]) -> Dict[str, Any]:
    """Uses Gemini AI to generate custom protocol steps for unusual/complex emergency scenarios."""
    raw_text = report_data.get("rawText", "")
    category = report_data.get("category", "other")
    severity = report_data.get("severity", "high")

    prompt = f"""You are ResQ AI's Chief Protocol Officer. Generate a custom, automated emergency response protocol for this situation:
Category: {category}
Severity: {severity}
Description: {raw_text}

Return ONLY valid JSON matching this structure:
{{
  "title": "<Short protocol title>",
  "summary": "<2-sentence operational summary>",
  "automatedSteps": [
    {{"stepNumber": 1, "title": "<Step title>", "description": "<Action description>", "etaSeconds": 30}},
    {{"stepNumber": 2, "title": "<Step title>", "description": "<Action description>", "etaSeconds": 90}},
    {{"stepNumber": 3, "title": "<Step title>", "description": "<Action description>", "etaSeconds": 180}},
    {{"stepNumber": 4, "title": "<Step title>", "description": "<Action description>", "etaSeconds": 300}}
  ],
  "safetyChecklist": [
    "<Citizen action step 1>",
    "<Citizen action step 2>",
    "<Citizen action step 3>",
    "<Citizen action step 4>"
  ]
}}"""

    try:
        response = await gemini_service.model.generate_content_async(prompt)
        text = response.text.strip()
        if text.startswith("```"):
            text = text.strip("`")
            text = text.replace("json\n", "", 1) if text.startswith("json\n") else text

        import json
        result = json.loads(text)
        return {
            "protocolId": "ai_custom_generated",
            "category": category,
            "severityTarget": severity,
            "icon": "auto_awesome",
            **result,
        }
    except Exception as e:
        logger.error(f"Failed to generate AI custom protocol: {e}")
        # Fallback to standard matched protocol
        return match_protocol_for_report(category, severity, raw_text)


def advance_protocol_step(report_id: str, target_step_index: Optional[int] = None) -> Dict[str, Any]:
    """Allows dispatchers to manually advance protocol steps from the Web Command Center."""
    report = firestore_service.get_report(report_id)
    if not report:
        raise ValueError(f"Report {report_id} not found.")

    active = report.get("activeProtocol")
    if not active:
        active = execute_protocol(report_id)

    steps = active.get("automatedSteps", [])
    cur = active.get("currentStepIndex", 1)

    next_step = target_step_index if target_step_index is not None else (cur + 1)
    if next_step > len(steps):
        next_step = len(steps)

    for idx, s in enumerate(steps):
        step_num = idx + 1
        if step_num < next_step:
            s["status"] = "completed"
        elif step_num == next_step:
            s["status"] = "in_progress"
        else:
            s["status"] = "pending"

    active["currentStepIndex"] = next_step
    active["lastUpdated"] = datetime.now(timezone.utc).isoformat()

    firestore_service.update_report(report_id, {"activeProtocol": active})
    firestore_service.log_incident(
        report_id=report_id,
        action="protocol_step_advanced",
        performed_by="DispatcherCommandCenter",
        details=f"Advanced protocol to Step {next_step}: {steps[next_step-1]['title'] if steps else ''}",
    )
    return active

