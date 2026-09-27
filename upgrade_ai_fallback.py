from pathlib import Path
import shutil

path = Path(r"C:\Users\chait\ai-breakdown-app\app\ai_service.py")
backup = path.with_name("ai_service_backup_before_engine_fallback.py")

text = path.read_text(encoding="utf-8")

# Create backup first
shutil.copy2(path, backup)

# ------------------------------------------------------------
# 1. Improve severity detection
# ------------------------------------------------------------

old_severity = '''        "engine shaking",
        "heavy vibration",
        "severe vibration",
        "wheel damage",'''

new_severity = '''        "engine shaking",
        "engine is shaking",
        "shaking badly",
        "engine shaking badly",
        "heavy vibration",
        "severe vibration",
        "wheel damage",'''

if old_severity not in text:
    raise SystemExit(
        "Severity pattern not found. No changes were made."
    )

text = text.replace(
    old_severity,
    new_severity,
    1
)

# ------------------------------------------------------------
# 2. Improve DTC detection for engine misfire
# ------------------------------------------------------------

old_dtc = '''            "engine shaking",
            "engine shakes",
            "rough engine",
            "rough idle",
            "rough running",
            "engine running rough",'''

new_dtc = '''            "engine shaking",
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
            "power loss",'''

if old_dtc not in text:
    raise SystemExit(
        "DTC pattern not found. No changes were made."
    )

text = text.replace(
    old_dtc,
    new_dtc,
    1
)

# ------------------------------------------------------------
# 3. Add specific engine-misfire fallback
# ------------------------------------------------------------

old_fallback = '''    category = infer_local_category(symptom)
    severity = infer_local_severity(symptom)
    dtc_codes = fallback_keyword_dtc_mapper(symptom)

    lower = symptom.lower()'''

new_fallback = '''    category = infer_local_category(symptom)
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
        severity = "HIGH"'''

if old_fallback not in text:
    raise SystemExit(
        "Fallback pattern not found. No changes were made."
    )

text = text.replace(
    old_fallback,
    new_fallback,
    1
)

# ------------------------------------------------------------
# 4. Make Engine diagnosis more specific
# ------------------------------------------------------------

old_details = '''    # Specific category details.
    understood, diagnosis, causes, action = local_category_details(category)

    safety = ['''

new_details = '''    # Specific category details.
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

    safety = ['''

if old_details not in text:
    raise SystemExit(
        "Engine details pattern not found. No changes were made."
    )

text = text.replace(
    old_details,
    new_details,
    1
)

# ------------------------------------------------------------
# 5. Improve confidence for recognized misfire
# ------------------------------------------------------------

old_confidence = '''        "confidence": 55.0,
        "diagnosis": diagnosis,'''

new_confidence = '''        "confidence": (
            65.0
            if category == "Engine" and "P0300" in dtc_codes
            else 55.0
        ),
        "diagnosis": diagnosis,'''

if old_confidence not in text:
    raise SystemExit(
        "Confidence pattern not found. No changes were made."
    )

text = text.replace(
    old_confidence,
    new_confidence,
    1
)

# ------------------------------------------------------------
# Save
# ------------------------------------------------------------

path.write_text(
    text,
    encoding="utf-8"
)

print("AI fallback upgraded successfully.")
print(f"Backup created: {backup}")
print(f"Updated file: {path}")