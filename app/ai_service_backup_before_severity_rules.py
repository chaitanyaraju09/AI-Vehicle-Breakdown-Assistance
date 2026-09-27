import json
import re
from typing import Any

from google import genai
from google.genai import types

from app.config import settings


# ============================================================
# CONSTANTS
# ============================================================

VALID_CATEGORIES = {
    "Engine",
    "Battery",
    "Electrical",
    "Tyre",
    "Brake",
    "Steering",
    "Suspension",
    "Transmission",
    "Clutch",
    "Cooling",
    "Fuel",
    "AC",
    "Ignition",
    "Exhaust",
    "Accident",
    "Lockout",
    "Towing",
    "General Repair",
    "Roadside Assistance",
}

VALID_SEVERITIES = {
    "LOW",
    "MEDIUM",
    "HIGH",
    "CRITICAL",
}


# ============================================================
# MAIN GEMINI DIAGNOSIS FUNCTION
# ============================================================

def analyze_symptoms_with_gemini(
    symptom_description: str,
) -> tuple[dict[str, Any], str]:
    """
    Analyze ANY driver-reported vehicle problem.

    Returns:
        (
            complete diagnosis dictionary,
            AI source
        )

    The system deliberately allows empty DTC lists because
    many physical/mechanical roadside problems do not have
    a directly applicable OBD-II code.
    """

    symptom = (symptom_description or "").strip()

    if not symptom:
        return (
            build_local_fallback(
                "Unknown vehicle problem"
            ),
            "Local Safety Fallback Engine",
        )

    if not settings.GEMINI_API_KEY:
        return (
            build_local_fallback(symptom),
            "Local Fallback Engine (Missing API Key)",
        )

    try:

        client = genai.Client(
            api_key=settings.GEMINI_API_KEY,
            http_options=types.HttpOptions(
                timeout=8000,
                retry_options=types.HttpRetryOptions(
                    attempts=1,
                ),
            ),
        )

        prompt = f"""
You are a professional automotive roadside diagnostic AI.

You must analyze ANY vehicle problem reported by a driver.

The driver may report:

Engine problems
Battery problems
Alternator problems
Starter problems
Electrical problems
Tyre/tire problems
Punctures
Wheel problems
Brake problems
Steering problems
Suspension problems
Clutch problems
Transmission problems
Gear problems
Cooling problems
Overheating
Coolant problems
Oil leaks
Fluid leaks
Fuel problems
Fuel pump problems
Fuel leaks
Ignition problems
Key/immobilizer problems
AC/HVAC problems
Lighting problems
Sensor problems
Warning lights
Check-engine light
Smoke
Strange noises
Knocking
Grinding
Vibration
Vehicle not starting
Vehicle stopping suddenly
Vehicle losing power
Accidents
Collision damage
Lockouts
Towing
Or ANY other vehicle-related roadside problem.

Driver report:

"{symptom}"

Analyze the actual problem carefully.

Return ONLY one valid JSON object.

Do not use Markdown.
Do not add text before or after the JSON.

Use EXACTLY these fields:

{{
  "problem_understood": "specific explanation of what the driver reported",
  "service_category": "one category from the allowed categories",
  "severity": "LOW, MEDIUM, HIGH, or CRITICAL",
  "confidence": 0,
  "diagnosis": "most likely diagnosis based on the symptoms",
  "possible_causes": [
    "cause 1",
    "cause 2",
    "cause 3"
  ],
  "safety_advice": [
    "safety instruction 1",
    "safety instruction 2"
  ],
  "recommended_action": "specific recommended next action",
  "roadside_assistance_required": true,
  "towing_recommended": false,
  "dtc_codes": [
    "P0300"
  ]
}}

ALLOWED SERVICE CATEGORIES:

Engine
Battery
Electrical
Tyre
Brake
Steering
Suspension
Transmission
Clutch
Cooling
Fuel
AC
Ignition
Exhaust
Accident
Lockout
Towing
General Repair
Roadside Assistance

CRITICAL RULES:

1. Understand the driver's actual problem.
2. Do not automatically classify everything as Engine.
3. A flat tyre must be classified as Tyre.
4. A puncture must be classified as Tyre.
5. A dead/weak battery must normally be Battery.
6. Brake problems must be Brake.
7. Steering problems must be Steering.
8. Overheating/coolant/radiator problems must normally be Cooling.
9. Transmission/gearbox problems must be Transmission.
10. Clutch problems must be Clutch.
11. AC problems must be AC.
12. Accident/collision damage must be Accident.
13. Lockout/key access problems must be Lockout.
14. A vehicle that cannot safely move may require Towing.
15. Severity must reflect actual safety risk.
16. A vehicle that cannot be driven because of a flat tyre should normally be HIGH.
17. Brake failure should normally be CRITICAL.
18. Steering failure should normally be CRITICAL.
19. Active fuel leakage should normally be CRITICAL.
20. Fire or severe smoke should normally be CRITICAL.
21. Serious overheating should normally be HIGH.
22. Do not tell the driver to continue driving when it may be unsafe.
23. Do not claim certainty when symptoms are insufficient.
24. confidence must be a number between 0 and 100.
25. DTCs are OPTIONAL.
26. Do NOT invent a DTC.
27. Mechanical problems may legitimately have NO DTC.
28. A flat tyre normally has no OBD-II DTC.
29. A brake mechanical failure may have no directly applicable DTC.
30. Accident damage normally has no DTC.
31. Lockout normally has no DTC.
32. If no DTC is genuinely applicable, return:
    "dtc_codes": []
33. Return a maximum of 3 DTC codes.
34. DTCs must be standard OBD-II-style codes.
35. Never use a DTC as a substitute for the actual mechanical diagnosis.
36. Always provide a useful response, even for an unusual or unclear problem.
37. If the description is unclear, use General Repair or Roadside Assistance.
38. For an unsafe or immobilized vehicle, roadside assistance should normally be true.
39. If the vehicle cannot safely be driven, consider towing_recommended true.
40. Keep the diagnosis specific to the reported symptoms.
"""


        interaction = client.interactions.create(
            model="gemini-3.6-flash",
            input=prompt,
        )

        response_text = (
            interaction.output_text or ""
        ).strip()

        parsed = extract_json_object(
            response_text
        )

        if not parsed:
            print(
                "GEMINI INVALID JSON:",
                response_text,
            )

            return (
                build_local_fallback(symptom),
                "Local Fallback Engine (Invalid Gemini Output)",
            )

        diagnosis = normalize_gemini_response(
            parsed,
            symptom,
        )

        return (
            diagnosis,
            "Gemini AI (gemini-3.6-flash)",
        )

    except Exception as e:

        print(
            "GEMINI API ERROR:",
            repr(e),
        )

        return (
            build_local_fallback(symptom),
            "Local Fallback Engine (Gemini Exception)",
        )


# ============================================================
# JSON EXTRACTION
# ============================================================

def extract_json_object(
    text: str,
) -> dict | None:

    text = (text or "").strip()

    if not text:
        return None

    # Remove Markdown fences if Gemini accidentally adds them.
    if text.startswith("```"):

        text = re.sub(
            r"^```(?:json)?\s*",
            "",
            text,
            flags=re.IGNORECASE,
        )

        text = re.sub(
            r"\s*```$",
            "",
            text,
        ).strip()

    # Try complete JSON first.
    try:

        parsed = json.loads(text)

        if isinstance(parsed, dict):
            return parsed

    except json.JSONDecodeError:
        pass

    # Try extracting the object from surrounding text.
    start = text.find("{")
    end = text.rfind("}")

    if start == -1 or end == -1:
        return None

    if end <= start:
        return None

    try:

        parsed = json.loads(
            text[start:end + 1]
        )

        if isinstance(parsed, dict):
            return parsed

    except json.JSONDecodeError:
        return None

    return None


# ============================================================
# DTC VALIDATION
# ============================================================

def clean_dtc_codes(
    codes,
) -> list[str]:

    if not isinstance(codes, list):
        return []

    cleaned = []

    for code in codes:

        if not isinstance(code, str):
            continue

        code = code.upper().strip()

        if re.fullmatch(
            r"[PBCU][0-3][0-9A-F]{3}",
            code,
        ):

            if code not in cleaned:
                cleaned.append(code)

        if len(cleaned) >= 3:
            break

    return cleaned


# ============================================================
# TEXT LIST NORMALIZATION
# ============================================================

def clean_text_list(
    value,
    default: list[str],
) -> list[str]:

    if not isinstance(value, list):
        return default

    result = []

    for item in value:

        if isinstance(item, str):

            item = item.strip()

            if item:
                result.append(item)

    if not result:
        return default

    return result[:6]


# ============================================================
# SAFE BOOLEAN NORMALIZATION
# ============================================================

def parse_bool(value, default: bool = False) -> bool:
    """Convert common JSON/string boolean representations safely."""
    if isinstance(value, bool):
        return value

    if isinstance(value, (int, float)):
        return bool(value)

    if isinstance(value, str):
        normalized = value.strip().lower()

        if normalized in {"true", "yes", "y", "1"}:
            return True

        if normalized in {"false", "no", "n", "0"}:
            return False

    return default


# ============================================================
# GEMINI RESPONSE NORMALIZATION
# ============================================================

def normalize_gemini_response(
    data: dict,
    symptom: str,
) -> dict:

    category = str(
        data.get(
            "service_category",
            "General Repair",
        )
    ).strip()

    # Case-insensitive category matching.
    category_lookup = {
        item.lower(): item
        for item in VALID_CATEGORIES
    }

    category = category_lookup.get(
        category.lower(),
        "General Repair",
    )

    severity = str(
        data.get(
            "severity",
            "MEDIUM",
        )
    ).upper().strip()

    if severity not in VALID_SEVERITIES:
        severity = infer_local_severity(
            symptom
        )

    try:

        confidence = float(
            data.get(
                "confidence",
                65,
            )
        )

    except (
        TypeError,
        ValueError,
    ):

        confidence = 65.0

    confidence = max(
        0.0,
        min(
            confidence,
            100.0,
        ),
    )

    problem_understood = str(
        data.get(
            "problem_understood",
            "",
        )
    ).strip()

    if not problem_understood:
        problem_understood = (
            f"Driver reports a possible "
            f"{category.lower()} problem."
        )

    diagnosis = str(
        data.get(
            "diagnosis",
            "",
        )
    ).strip()

    if not diagnosis:
        diagnosis = (
            "The reported symptoms require "
            "professional vehicle inspection."
        )

    possible_causes = clean_text_list(
        data.get("possible_causes"),
        [
            "The exact cause cannot be confirmed "
            "from symptoms alone.",
            "Professional vehicle inspection is recommended.",
        ],
    )

    safety_advice = clean_text_list(
        data.get("safety_advice"),
        [
            "Move to a safe location if the vehicle "
            "cannot be operated safely.",
            "Do not continue driving if doing so "
            "could create a safety risk.",
        ],
    )

    recommended_action = str(
        data.get(
            "recommended_action",
            "",
        )
    ).strip()

    if not recommended_action:
        recommended_action = (
            "Request roadside assistance for "
            "professional vehicle inspection."
        )

    roadside_required = parse_bool(
        data.get(
            "roadside_assistance_required",
            True,
        ),
        default=True,
    )

    towing_recommended = parse_bool(
        data.get(
            "towing_recommended",
            False,
        ),
        default=False,
    )

    dtc_codes = clean_dtc_codes(
        data.get(
            "dtc_codes",
            [],
        )
    )

    # Safety override.
    if severity == "CRITICAL":
        roadside_required = True

    if category in {
        "Brake",
        "Steering",
        "Accident",
        "Towing",
    }:
        roadside_required = True

    # An immobilized vehicle should generally be considered
    # for towing.
    lower = symptom.lower()

    if (
        "cannot drive" in lower
        or "can't drive" in lower
        or "cannot move" in lower
        or "can't move" in lower
    ):
        roadside_required = True

    if category == "Tyre" and (
        "flat" in lower
        or "puncture" in lower
        or "punctured" in lower
        or "burst" in lower
    ):
        towing_recommended = (
            towing_recommended
            or severity in {
                "HIGH",
                "CRITICAL",
            }
        )

    return {
        "problem_understood": problem_understood,
        "service_category": category,
        "severity": severity,
        "confidence": confidence,
        "diagnosis": diagnosis,
        "possible_causes": possible_causes,
        "safety_advice": safety_advice,
        "recommended_action": recommended_action,
        "roadside_assistance_required": roadside_required,
        "towing_recommended": towing_recommended,
        "dtc_codes": dtc_codes,
    }


# ============================================================
# LOCAL SEVERITY ENGINE
# ============================================================

def infer_local_severity(
    symptom: str,
) -> str:
    """
    Conservative offline severity classifier.

    This is intentionally symptom-based rather than pretending to
    make a confirmed mechanical diagnosis.
    """
    text = (symptom or "").lower()

    critical = [
        "brake failure",
        "brakes failed",
        "no brakes",
        "brake completely gone",
        "brake pedal goes to floor",
        "steering failure",
        "steering failed",
        "cannot steer",
        "fuel leak",
        "petrol leak",
        "diesel leak",
        "fuel is leaking",
        "fuel dripping",
        "vehicle on fire",
        "car on fire",
        "engine fire",
        "fire under hood",
        "fire under bonnet",
        "smoke inside",
        "heavy smoke from engine",
        "major accident",
        "severe accident",
        "serious collision",
        "rollover",
    ]

    high = [
        "flat tyre",
        "flat tire",
        "puncture",
        "punctured",
        "tyre burst",
        "tire burst",
        "burst tyre",
        "burst tire",
        "cannot drive",
        "can't drive",
        "cannot move",
        "can't move",
        "vehicle immobilized",
        "vehicle immobilised",
        "overheating",
        "overheat",
        "temperature warning",
        "temperature gauge red",
        "engine shaking",
        "engine is shaking",
        "shaking badly",
        "engine shaking badly",
        "heavy vibration",
        "severe vibration",
        "wheel damage",
        "broken wheel",
        "wheel came off",
        "vehicle stopped",
        "stopped suddenly",
        "lost control",
        "gearbox locked",
        "transmission locked",
        "clutch completely failed",
        "accelerator stuck",
        "throttle stuck",
        "smoke from engine",
        "smoke from bonnet",
        "smoke from hood",
    ]

    medium = [
        "battery",
        "not starting",
        "won't start",
        "wont start",
        "doesn't start",
        "doesnt start",
        "starting problem",
        "starter problem",
        "alternator",
        "strange noise",
        "rough idle",
        "rough running",
        "engine light",
        "check engine",
        "warning light",
        "stalling",
        "gear slipping",
        "clutch slipping",
        "ac not working",
        "air conditioner not working",
        "headlight not working",
        "indicator not working",
        "power window not working",
    ]

    if any(item in text for item in critical):
        return "CRITICAL"

    if any(item in text for item in high):
        return "HIGH"

    if any(item in text for item in medium):
        return "MEDIUM"

    return "LOW"


# ============================================================
# LOCAL CATEGORY ENGINE
# ============================================================

def infer_local_category(
    symptom: str,
) -> str:
    """
    Offline category inference used when Gemini is unavailable.

    The ordering intentionally gives safety-critical/specific
    component terms priority over broad words such as "engine".
    """
    text = (symptom or "").lower()

    rules = [
        (
            "Accident",
            [
                "accident",
                "crash",
                "collision",
                "hit by",
                "hit a",
                "rear ended",
                "rear-ended",
                "rollover",
            ],
        ),
        (
            "Brake",
            [
                "brake",
                "braking",
                "brake pedal",
            ],
        ),
        (
            "Steering",
            [
                "steering",
                "steering wheel",
                "cannot steer",
                "can't steer",
                "hard to steer",
            ],
        ),
        (
            "Tyre",
            [
                "tyre",
                "tire",
                "puncture",
                "flat wheel",
                "flat tyre",
                "flat tire",
                "wheel puncture",
                "tyre burst",
                "tire burst",
            ],
        ),
        (
            "Suspension",
            [
                "suspension",
                "shock absorber",
                "strut",
                "bumpy ride",
                "vehicle bouncing",
            ],
        ),
        (
            "Transmission",
            [
                "transmission",
                "gearbox",
                "gear box",
                "gear slipping",
                "gear problem",
                "gear stuck",
                "gear not engaging",
                "automatic transmission",
                "manual transmission",
            ],
        ),
        (
            "Clutch",
            [
                "clutch",
                "clutch slipping",
                "clutch pedal",
                "clutch plate",
            ],
        ),
        (
            "Cooling",
            [
                "overheating",
                "overheat",
                "coolant",
                "radiator",
                "cooling fan",
                "temperature rising",
                "temperature gauge",
                "engine temperature",
                "hot engine",
            ],
        ),
        (
            "Fuel",
            [
                "fuel pump",
                "fuel leak",
                "petrol leak",
                "diesel leak",
                "fuel problem",
                "fuel injection",
                "injector",
                "low fuel pressure",
                "ran out of fuel",
                "out of fuel",
            ],
        ),
        (
            "Battery",
            [
                "battery",
                "dead battery",
                "weak battery",
                "battery dead",
                "battery drained",
                "battery discharged",
                "jump start",
                "jump-start",
            ],
        ),
        (
            "Electrical",
            [
                "alternator",
                "charging",
                "electrical",
                "electric",
                "fuse",
                "wiring",
                "wire",
                "short circuit",
                "power supply",
                "not getting power",
                "starter motor",
                "starter",
                "headlight",
                "tail light",
                "indicator",
                "horn",
                "power window",
                "central locking",
                "immobilizer",
                "immobiliser",
                "ev",
                "electric vehicle",
                "charging port",
                "charging station",
                "vehicle not charging",
            ],
        ),
        (
            "AC",
            [
                "air conditioner",
                "air conditioning",
                "ac not",
                "a/c",
                "ac cooling",
                "ac gas",
                "compressor",
                "blower",
                "no cold air",
                "not cooling inside",
            ],
        ),
        (
            "Ignition",
            [
                "ignition",
                "spark plug",
                "ignition coil",
                "key not turning",
                "key won't turn",
                "key wont turn",
            ],
        ),
        (
            "Lockout",
            [
                "locked out",
                "lockout",
                "lock out",
                "keys locked",
                "key locked",
                "keys inside",
                "key inside",
                "lost key",
                "lost keys",
                "cannot unlock",
                "can't unlock",
            ],
        ),
        (
            "Towing",
            [
                "towing",
                "tow truck",
                "need a tow",
                "need towing",
                "tow my car",
            ],
        ),
        (
            "Exhaust",
            [
                "exhaust",
                "catalytic converter",
                "catalytic",
                "exhaust smoke",
                "exhaust leak",
            ],
        ),
        (
            "Engine",
            [
                "engine",
                "misfire",
                "engine shaking",
                "engine shakes",
                "shaking",
                "rough",
                "rough idle",
                "rough running",
                "stalling",
                "losing power",
                "power loss",
                "knocking",
                "tapping noise",
                "engine noise",
                "won't start",
                "wont start",
                "not starting",
            ],
        ),
    ]

    for category, keywords in rules:
        if any(keyword in text for keyword in keywords):
            return category

    return "General Repair"


# ============================================================
# LOCAL DTC FALLBACK
# ============================================================

def fallback_keyword_dtc_mapper(
    symptom: str,
) -> list[str]:
    """
    Map only conservative, symptom-supported DTCs.

    Physical roadside failures such as flat tyres, brakes,
    accidents and lockouts intentionally return no DTC.
    """
    text = (symptom or "").lower()

    matched = []

    # Engine misfire.
    if any(
        word in text
        for word in [
            "misfire",
            "engine shaking",
            "engine is shaking",
            "engine shaking badly",
            "shaking badly",
            "engine shakes",
            "rough engine",
            "rough idle",
            "rough running",
            "running rough",
            "engine running rough",
            "losing power",
            "power loss",
        ]
    ):
        matched.append("P0300")

    # Lean condition.
    if any(
        word in text
        for word in [
            "lean",
            "running lean",
            "system too lean",
        ]
    ):
        matched.append("P0171")

    # Catalytic converter efficiency.
    if any(
        word in text
        for word in [
            "catalytic converter",
            "catalytic",
        ]
    ):
        matched.append("P0420")

    # Cooling / thermostat.
    if any(
        word in text
        for word in [
            "thermostat",
            "coolant temperature",
            "engine temperature sensor",
            "temperature sensor",
        ]
    ):
        matched.append("P0128")

    # EVAP.
    if any(
        word in text
        for word in [
            "gas cap",
            "evap",
            "evaporative emission",
        ]
    ):
        matched.append("P0455")

    # System voltage.
    if any(
        word in text
        for word in [
            "low system voltage",
            "system voltage low",
            "voltage is low",
            "battery voltage low",
        ]
    ):
        matched.append("P0562")

    # Camshaft position.
    if any(
        word in text
        for word in [
            "camshaft sensor",
            "cam sensor",
            "cam position sensor",
        ]
    ):
        matched.append("P0340")

    # Oxygen sensor.
    if any(
        word in text
        for word in [
            "oxygen sensor",
            "o2 sensor",
            "o2",
        ]
    ):
        matched.append("P0130")

    # Limit to three unique codes.
    return list(dict.fromkeys(matched))[:3]


# ============================================================
# LOCAL RESPONSE DETAILS
# ============================================================

def local_category_details(category: str) -> tuple[str, str, list[str], str]:
    """Return understood, diagnosis, causes and action for a category."""

    details = {
        "Tyre": (
            "The driver appears to have a tyre or wheel-related problem.",
            "Possible tyre puncture, air loss or tyre damage.",
            [
                "Possible puncture",
                "Air pressure loss",
                "Tyre or valve damage",
            ],
            "Request tyre roadside assistance for inspection, repair or replacement.",
        ),
        "Battery": (
            "The driver appears to have a battery or starting-system problem.",
            "Possible discharged or weak battery.",
            [
                "Discharged battery",
                "Battery deterioration",
                "Possible charging-system issue",
            ],
            "Request battery roadside assistance for testing or jump-starting.",
        ),
        "Electrical": (
            "The driver appears to have an electrical or vehicle power-system problem.",
            "Possible electrical, charging, wiring or power-supply fault.",
            [
                "Alternator or charging-system issue",
                "Fuse, wiring or connection problem",
                "Starter, lighting or electrical-component fault",
            ],
            "Request electrical roadside assistance for electrical-system testing.",
        ),
        "Brake": (
            "The driver appears to have a braking-system problem.",
            "Possible brake-system fault requiring inspection.",
            [
                "Brake component wear",
                "Hydraulic problem",
                "Mechanical brake problem",
            ],
            "Avoid driving if braking performance is unsafe and request roadside assistance.",
        ),
        "Steering": (
            "The driver appears to have a steering-system problem.",
            "Possible steering linkage, power-assist or steering-component fault.",
            [
                "Steering component wear or damage",
                "Power-steering or steering-assist issue",
                "Mechanical steering-system fault",
            ],
            "Do not drive if steering control is unsafe; request roadside assistance or towing.",
        ),
        "Suspension": (
            "The driver appears to have a suspension or ride-control problem.",
            "Possible suspension, shock absorber or strut fault.",
            [
                "Worn shock absorber or strut",
                "Suspension component damage",
                "Loose or worn suspension connection",
            ],
            "Request suspension inspection, especially if vehicle handling is unstable.",
        ),
        "Transmission": (
            "The driver appears to have a transmission or gearbox problem.",
            "Possible transmission, gearbox or gear-selection fault.",
            [
                "Transmission fluid or pressure issue",
                "Gear-selection or clutch-related problem",
                "Internal transmission wear or fault",
            ],
            "Avoid forcing gears and request transmission inspection or towing if the vehicle cannot move safely.",
        ),
        "Clutch": (
            "The driver appears to have a clutch-system problem.",
            "Possible clutch wear, slipping or clutch-control fault.",
            [
                "Worn clutch disc",
                "Clutch hydraulic or cable problem",
                "Clutch pressure-plate or release-system issue",
            ],
            "Request clutch inspection and avoid continued driving if gear engagement is unsafe.",
        ),
        "Cooling": (
            "The driver appears to have an engine cooling-system problem.",
            "Possible overheating or cooling-system fault.",
            [
                "Low coolant",
                "Radiator problem",
                "Thermostat or cooling-fan problem",
            ],
            "Stop safely, allow the engine to cool and request cooling-system inspection.",
        ),
        "Fuel": (
            "The driver appears to have a fuel-system problem.",
            "Possible fuel-delivery, fuel-pressure or fuel-leak issue.",
            [
                "Fuel pump or pressure problem",
                "Injector or fuel-delivery issue",
                "Fuel-line or tank problem",
            ],
            "Request fuel-system roadside assistance; if fuel is leaking, do not operate the vehicle.",
        ),
        "AC": (
            "The driver appears to have an air-conditioning or HVAC problem.",
            "Possible AC cooling, compressor, refrigerant or blower fault.",
            [
                "Low refrigerant or leak",
                "Compressor or clutch problem",
                "Blower or HVAC control issue",
            ],
            "Request AC/HVAC inspection; roadside repair may be limited depending on the fault.",
        ),
        "Ignition": (
            "The driver appears to have an ignition or starting-control problem.",
            "Possible ignition, spark or key/start-control fault.",
            [
                "Spark plug or ignition-coil issue",
                "Ignition-switch problem",
                "Key, immobilizer or start-control issue",
            ],
            "Request ignition/starting-system diagnosis rather than repeatedly attempting to start the vehicle.",
        ),
        "Exhaust": (
            "The driver appears to have an exhaust-system problem.",
            "Possible exhaust leak, catalytic-converter or exhaust-component fault.",
            [
                "Exhaust leak",
                "Catalytic-converter problem",
                "Exhaust-component damage",
            ],
            "Request exhaust-system inspection; avoid driving if fumes enter the cabin.",
        ),
        "Accident": (
            "The driver reports an accident or collision-related problem.",
            "Vehicle requires post-accident safety and mechanical inspection.",
            [
                "Collision damage",
                "Mechanical damage",
                "Electrical or body-system damage",
            ],
            "Move to a safe location if possible and request roadside or towing assistance.",
        ),
        "Lockout": (
            "The driver appears to be locked out of the vehicle.",
            "Vehicle access is unavailable because of a key or lockout issue.",
            [
                "Keys locked inside vehicle",
                "Lost or unavailable key",
                "Lock or key-system problem",
            ],
            "Request vehicle lockout assistance.",
        ),
        "Towing": (
            "The driver reports that towing assistance is required.",
            "Vehicle may be immobilized or unsafe to drive.",
            [
                "Vehicle cannot move safely",
                "Mechanical breakdown",
                "Accident or other immobilizing condition",
            ],
            "Request a suitable tow vehicle and avoid operating the vehicle if it is unsafe.",
        ),
        "Engine": (
            "The driver appears to have an engine-related performance problem.",
            "Possible engine performance, combustion, air/fuel or ignition-related problem.",
            [
                "Ignition-system problem",
                "Fuel-delivery problem",
                "Air, sensor or engine-control problem",
            ],
            "Request professional engine diagnosis and roadside assistance.",
        ),
    }

    return details.get(
        category,
        (
            "The driver has reported a vehicle problem that requires further assessment.",
            "The exact physical fault cannot be confirmed from the reported symptoms alone.",
            [
                "Cause cannot be confirmed from symptoms alone",
                "Vehicle inspection is recommended",
            ],
            "Request roadside assistance for professional vehicle inspection and diagnosis.",
        ),
    )


# ============================================================
# COMPLETE LOCAL FALLBACK
# ============================================================

def build_local_fallback(
    symptom: str,
) -> dict:
    """
    Complete offline fallback.

    It always returns the same structured response expected by
    the FastAPI endpoint, even when Gemini is unavailable.
    """
    symptom = (symptom or "").strip()

    if not symptom:
        symptom = "Unknown vehicle problem"

    category = infer_local_category(symptom)
    severity = infer_local_severity(symptom)
    dtc_codes = fallback_keyword_dtc_mapper(symptom)

    lower = symptom.lower()

    # Specific engine-misfire fallback for common roadside wording.
    # Handles phrases such as:
    # engine is shaking badly
    # engine shaking
    # running rough
    # rough idle
    # losing power

    engine_misfire_signal = any(
        phrase in lower
        for phrase in [
            "misfire",
            "engine is shaking",
            "engine shaking",
            "shaking badly",
            "engine shakes",
            "rough engine",
            "rough idle",
            "rough running",
            "running rough",
            "engine running rough",
        ]
    )

    if engine_misfire_signal and "P0300" not in dtc_codes:
        dtc_codes.insert(0, "P0300")

    if engine_misfire_signal and any(
        phrase in lower
        for phrase in [
            "losing power",
            "power loss",
            "lost power",
            "severe shaking",
            "shaking badly",
            "engine shaking badly",
        ]
    ):
        severity = "HIGH"

    # Towing is recommended for critical or clearly immobilized cases.
    towing = (
        severity == "CRITICAL"
        or any(
            word in lower
            for word in [
                "cannot move",
                "can't move",
                "cannot drive",
                "can't drive",
                "vehicle immobilized",
                "vehicle immobilised",
                "towing",
                "tow truck",
                "need a tow",
            ]
        )
    )

    # Specific category details.
    understood, diagnosis, causes, action = local_category_details(category)

    if category == "Engine" and "P0300" in dtc_codes:
        understood = (
            "The driver appears to have an engine misfire "
            "or rough-running problem."
        )

        diagnosis = (
            "Possible engine misfire causing shaking, "
            "rough running and power loss."
        )

        causes = [
            "Ignition-system problem such as spark plug "
            "or ignition-coil fault",
            "Fuel-delivery or injector problem",
            "Air, sensor or engine-control problem",
            "Further diagnostic scanning is recommended "
            "to confirm the cause",
        ]

        action = (
            "Request professional engine diagnostic assistance "
            "and avoid continued driving if the shaking or "
            "power loss is severe."
        )

    safety = [
        "Move to a safe location if the vehicle cannot be operated safely.",
        "Use hazard lights when stopped in or near traffic.",
    ]

    if severity in {"HIGH", "CRITICAL"}:
        safety.append(
            "Do not continue driving if doing so could be unsafe."
        )

    if category == "Cooling":
        safety.append(
            "Do not open the radiator or coolant reservoir while the engine is hot."
        )

    if category == "Tyre":
        safety.append(
            "Do not drive at normal speed on a severely damaged or flat tyre."
        )

    if category == "Brake":
        safety.append(
            "Do not drive if braking performance is significantly reduced."
        )

    if category == "Steering":
        safety.append(
            "Do not drive if steering control is significantly reduced."
        )

    if category == "Fuel" and any(
        phrase in lower
        for phrase in [
            "fuel leak",
            "petrol leak",
            "diesel leak",
            "fuel is leaking",
            "fuel dripping",
        ]
    ):
        safety.append(
            "Keep flames, sparks and other ignition sources away from the vehicle."
        )

    if category == "Exhaust" and any(
        phrase in lower
        for phrase in [
            "exhaust leak",
            "fumes",
            "exhaust smell",
        ]
    ):
        safety.append(
            "Do not remain inside the vehicle if exhaust fumes may be entering the cabin."
        )

    if category == "Accident":
        safety.append(
            "If anyone is injured, contact emergency services before arranging vehicle assistance."
        )

    # If a flat/punctured tyre is immobilizing the vehicle, towing is useful.
    if category == "Tyre" and any(
        phrase in lower
        for phrase in [
            "flat",
            "puncture",
            "punctured",
            "burst",
        ]
    ) and severity in {"HIGH", "CRITICAL"}:
        towing = True

    # Brake/steering/accident criticality should always trigger roadside help.
    roadside_required = True

    # Battery may have a conservative local DTC when low voltage is explicitly reported.
    # We deliberately do not invent a code for an ordinary flat tyre, brake fault,
    # accident, lockout or generic mechanical problem.
    return {
        "problem_understood": understood,
        "service_category": category,
        "severity": severity,
        "confidence": (
            65.0
            if category == "Engine" and "P0300" in dtc_codes
            else 55.0
        ),
        "diagnosis": diagnosis,
        "possible_causes": causes[:6],
        "safety_advice": safety[:6],
        "recommended_action": action,
        "roadside_assistance_required": roadside_required,
        "towing_recommended": towing,
        "dtc_codes": dtc_codes,
    }
