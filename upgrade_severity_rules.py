from pathlib import Path
import shutil

path = Path(r"C:\Users\chait\ai-breakdown-app\app\ai_service.py")
backup = path.with_name("ai_service_backup_before_severity_rules.py")

text = path.read_text(encoding="utf-8")

# Create backup
shutil.copy2(path, backup)

# ------------------------------------------------------------
# 1. Add stronger HIGH/CRITICAL severity phrases
# ------------------------------------------------------------

old_high = '''        "engine shaking badly",
        "heavy vibration",
        "severe vibration",
        "wheel damage",'''

new_high = '''        "engine shaking badly",
        "transmission slipping",
        "slipping transmission",
        "gear slipping",
        "clutch pedal is very hard",
        "clutch is very hard",
        "difficulty moving after releasing clutch",
        "difficulty moving",
        "hard to shift gears",
        "gear shifting problem",
        "heavy vibration",
        "severe vibration",
        "wheel damage",'''

if old_high not in text:
    raise SystemExit(
        "HIGH severity pattern not found. No changes were made."
    )

text = text.replace(old_high, new_high, 1)

# ------------------------------------------------------------
# 2. Add critical steering/brake phrases
# ------------------------------------------------------------

old_critical = '''        "brake failure",
        "brakes not working",
        "no brakes",'''

new_critical = '''        "brake failure",
        "brakes not working",
        "no brakes",
        "cannot control the direction",
        "cannot control direction",
        "steering control is lost",
        "steering control lost",
        "cannot control the steering",
        "steering is not responding",
        "steering not responding",
        "steering failure",'''

if old_critical in text:
    text = text.replace(old_critical, new_critical, 1)
else:
    # If the exact block differs, inject the steering phrases
    # near the first CRITICAL phrase list.
    marker = '''        "brake failure",'''
    if marker not in text:
        raise SystemExit(
            "CRITICAL severity pattern not found. No changes were made."
        )

    text = text.replace(
        marker,
        '''        "brake failure",
        "cannot control the direction",
        "cannot control direction",
        "steering control is lost",
        "steering control lost",
        "cannot control the steering",
        "steering is not responding",
        "steering not responding",
        "steering failure",''',
        1
    )

# ------------------------------------------------------------
# 3. Add targeted severity override inside local fallback
# ------------------------------------------------------------

old_fallback = '''    if engine_misfire_signal and any(
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

new_fallback = '''    if engine_misfire_signal and any(
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

    # Transmission problems.
    transmission_high_signal = any(
        phrase in lower
        for phrase in [
            "transmission slipping",
            "slipping transmission",
            "gear slipping",
            "hard to shift gears",
            "gear shifting problem",
            "cannot change gears",
            "cannot shift gears",
        ]
    )

    if category == "Transmission" and transmission_high_signal:
        severity = "HIGH"

    # Clutch problems.
    clutch_high_signal = any(
        phrase in lower
        for phrase in [
            "clutch pedal is very hard",
            "clutch is very hard",
            "hard clutch",
            "difficulty moving after releasing clutch",
            "difficulty moving",
            "clutch not engaging",
            "clutch slipping badly",
        ]
    )

    if category == "Clutch" and clutch_high_signal:
        severity = "HIGH"

    # Steering problems that affect vehicle control.
    steering_critical_signal = any(
        phrase in lower
        for phrase in [
            "cannot control the direction",
            "cannot control direction",
            "cannot control the steering",
            "steering control is lost",
            "steering control lost",
            "steering is not responding",
            "steering not responding",
            "steering failure",
            "very hard steering",
            "steering has become very hard",
        ]
    )

    if category == "Steering" and steering_critical_signal:
        severity = "CRITICAL"

    # Brake-control problems are critical.
    brake_critical_signal = any(
        phrase in lower
        for phrase in [
            "brake failure",
            "brakes are not working",
            "brakes not working",
            "no brakes",
            "cannot stop",
            "brake pedal feels very soft",
            "soft brake pedal",
        ]
    )

    if category == "Brake" and brake_critical_signal:
        severity = "CRITICAL"'''

if old_fallback not in text:
    raise SystemExit(
        "Fallback severity block not found. No changes were made."
    )

text = text.replace(
    old_fallback,
    new_fallback,
    1
)

# ------------------------------------------------------------
# 4. Save
# ------------------------------------------------------------

path.write_text(text, encoding="utf-8")

print("Severity rules upgraded successfully.")
print(f"Backup created: {backup}")
print(f"Updated file: {path}")