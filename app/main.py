from contextlib import asynccontextmanager
import logging
from math import radians, sin, cos, sqrt, atan2
from typing import List

from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.concurrency import run_in_threadpool
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from starlette.exceptions import HTTPException as StarletteHTTPException

from app.config import settings

from app.database import engine, Base, get_db
from app.models import User, DTC, Mechanic, AssistanceRequest

from app.schemas import (
    UserCreate,
    UserResponse,
    Token,
    DTCCreate,
    DTCResponse,
    MechanicCreate,
    MechanicResponse,
    AssistanceRequestCreate,
    AssistanceRequestResponse,
    MechanicMatchResponse,
    MechanicMatchResult,
    SymptomAnalysisRequest,
    SymptomAnalysisResponse,
    DTCInfo,
)

from app.auth import (
    hash_password,
    verify_password,
    create_access_token,
    get_current_user,
)

from app.ai_service import analyze_symptoms_with_gemini


# ============================================================
# DATABASE STARTUP
# ============================================================

@asynccontextmanager
async def lifespan(app: FastAPI):
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    yield


logger = logging.getLogger("vehicle_assistance")

# ============================================================
# FASTAPI APP
# ============================================================

app = FastAPI(
    title="Vehicle Assistance API",
    version="1.0.0",
    description=(
        "AI-Based GPS-Enabled Vehicle Breakdown "
        "Assistance System API"
    ),
    lifespan=lifespan,
)

# ============================================================
# CORS CONFIGURATION
# ============================================================

cors_origins = settings.cors_origins_list
allow_all = "*" in cors_origins

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"] if allow_all else cors_origins,
    allow_credentials=not allow_all,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ============================================================
# CENTRALIZED ERROR HANDLING
# ============================================================

@app.exception_handler(StarletteHTTPException)
async def http_exception_handler(request, exc: StarletteHTTPException):
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "error": True,
            "status_code": exc.status_code,
            "detail": exc.detail,
        },
    )


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request, exc: RequestValidationError):
    errors = exc.errors()
    first_msg = (
        errors[0].get("msg", "Validation error")
        if errors
        else "Invalid request data"
    )
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={
            "error": True,
            "status_code": 422,
            "detail": first_msg,
            "errors": errors,
        },
    )


@app.exception_handler(Exception)
async def generic_exception_handler(request, exc: Exception):
    logger.exception(f"Unhandled server error on {request.url.path}: {exc}")
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "error": True,
            "status_code": 500,
            "detail": "An unexpected server error occurred. Please try again.",
        },
    )


# ============================================================
# HEALTH & ROOT
# ============================================================

@app.get("/health", tags=["System"])
async def health_check():
    return {
        "status": "healthy",
        "service": "Vehicle Assistance API",
        "environment": settings.ENVIRONMENT,
        "version": "1.0.0",
    }


@app.get("/")
async def root():
    return {
        "status": "online",
        "message": "Vehicle Assistance API is running",
    }


# ============================================================
# ROLE-BASED ACCESS CONTROL
# ============================================================

def require_role(required_role: str):

    async def role_checker(
        current_user: User = Depends(get_current_user),
    ):

        if current_user.role.upper() != required_role.upper():
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=(
                    f"Access denied: This operation requires "
                    f"'{required_role.upper()}' role."
                ),
            )

        return current_user

    return role_checker


# ============================================================
# AUTHENTICATION - REGISTER
# ============================================================

@app.post(
    "/auth/register",
    response_model=UserResponse,
)
async def register_user(
    user_data: UserCreate,
    db: AsyncSession = Depends(get_db),
):

    existing_user = await db.scalar(
        select(User).where(
            User.email == user_data.email
        )
    )

    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered",
        )

    role = user_data.role.upper()

    if role not in ["DRIVER", "MECHANIC"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Role must be DRIVER or MECHANIC",
        )

    user = User(
        email=user_data.email,
        hashed_password=hash_password(
            user_data.password
        ),
        full_name=user_data.full_name,
        role=role,
        is_active=True,
    )

    db.add(user)

    await db.commit()
    await db.refresh(user)

    return user


# ============================================================
# AUTHENTICATION - LOGIN
# ============================================================

@app.post(
    "/auth/login",
    response_model=Token,
)
async def login_user(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: AsyncSession = Depends(get_db),
):

    user = await db.scalar(
        select(User).where(
            User.email == form_data.username
        )
    )

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
        )

    if not verify_password(
        form_data.password,
        user.hashed_password,
    ):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
        )

    access_token = create_access_token(
        {
            "sub": user.email,
            "role": user.role,
        }
    )

    return {
        "access_token": access_token,
        "token_type": "bearer",
    }


# ============================================================
# AUTHENTICATION - CURRENT USER
# ============================================================

@app.get(
    "/auth/me",
    response_model=UserResponse,
)
async def get_my_profile(
    current_user: User = Depends(get_current_user),
):

    return current_user


# ============================================================
# DTC LOOKUP
# ============================================================

@app.get(
    "/dtc/{code}",
    response_model=DTCResponse,
)
async def get_dtc(
    code: str,
    db: AsyncSession = Depends(get_db),
):

    dtc = await db.scalar(
        select(DTC).where(
            DTC.code == code.upper()
        )
    )

    if not dtc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="DTC code not found",
        )

    return dtc


# ============================================================
# CREATE DTC
# ============================================================

@app.post(
    "/dtc/",
    response_model=DTCResponse,
)
async def create_dtc(
    dtc_data: DTCCreate,
    db: AsyncSession = Depends(get_db),
):

    existing_dtc = await db.scalar(
        select(DTC).where(
            DTC.code == dtc_data.code.upper()
        )
    )

    if existing_dtc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="DTC code already exists",
        )

    dtc = DTC(
        code=dtc_data.code.upper(),
        description=dtc_data.description,
        severity=dtc_data.severity,
        possible_causes=dtc_data.possible_causes,
        recommended_action=dtc_data.recommended_action,
    )

    db.add(dtc)

    await db.commit()
    await db.refresh(dtc)

    return dtc


# ============================================================
# AI DIAGNOSIS HELPERS
# ============================================================

def determine_service_category(
    symptom: str,
    dtc_codes: list[str],
) -> str:

    text = symptom.lower()

    # Explicit physical/roadside problems first.
    if any(
        word in text
        for word in [
            "flat tyre",
            "flat tire",
            "puncture",
            "punctured tyre",
            "punctured tire",
            "tyre burst",
            "tire burst",
            "tyre damage",
            "tire damage",
            "wheel",
        ]
    ):
        return "Tyre"

    if any(
        word in text
        for word in [
            "brake",
            "brakes",
            "braking",
        ]
    ):
        return "Brake"

    if any(
        word in text
        for word in [
            "steering",
            "steering wheel",
        ]
    ):
        return "Steering"

    if any(
        word in text
        for word in [
            "clutch",
            "gear",
            "gearbox",
            "transmission",
        ]
    ):
        return "Transmission"

    if any(
        word in text
        for word in [
            "battery",
            "battery dead",
            "battery drained",
            "jump start",
        ]
    ):
        return "Battery"

    if any(
        word in text
        for word in [
            "alternator",
            "charging",
            "not charging",
        ]
    ):
        return "Electrical"

    if any(
        word in text
        for word in [
            "overheating",
            "overheat",
            "coolant",
            "radiator",
            "temperature rising",
            "engine temperature",
        ]
    ):
        return "Cooling"

    if any(
        word in text
        for word in [
            "fuel pump",
            "fuel leak",
            "petrol leak",
            "diesel leak",
            "fuel",
        ]
    ):
        return "Fuel"

    if any(
        word in text
        for word in [
            "ac ",
            "a/c",
            "air conditioner",
            "air conditioning",
        ]
    ):
        return "AC"

    if any(
        word in text
        for word in [
            "accident",
            "crash",
            "collision",
        ]
    ):
        return "Accident"

    if any(
        word in text
        for word in [
            "locked out",
            "lockout",
            "keys locked",
            "key locked",
        ]
    ):
        return "Lockout"

    if any(
        word in text
        for word in [
            "tow",
            "towing",
            "cannot move",
            "can't move",
        ]
    ):
        return "Towing"

    # DTC-based fallback.
    detected_codes = {
        code.upper()
        for code in dtc_codes
    }

    category_priority = [
        ("Fuel", {"P0455", "P0171"}),
        ("Exhaust", {"P0420"}),
        ("Cooling", {"P0128"}),
        ("Engine", {"P0300", "P0301", "P0302", "P0303", "P0304"}),
    ]

    for category, codes in category_priority:
        if detected_codes & codes:
            return category

    if any(
        word in text
        for word in [
            "engine",
            "misfire",
            "shaking",
            "rough",
            "stalling",
            "not starting",
            "won't start",
            "wont start",
            "starting problem",
        ]
    ):
        return "Engine"

    return "General Repair"


def determine_severity(
    symptom: str,
) -> str:

    text = symptom.lower()

    critical_keywords = [
        "brake failure",
        "brakes failed",
        "no brakes",
        "steering failure",
        "steering failed",
        "fire",
        "vehicle on fire",
        "smoke inside",
        "fuel leak",
        "petrol leak",
        "diesel leak",
        "major accident",
        "accident",
    ]

    high_keywords = [
        "overheating",
        "overheat",
        "engine shaking",
        "engine misfire",
        "heavy vibration",
        "wheel damage",
        "tyre burst",
        "tire burst",
        "flat tyre",
        "flat tire",
        "puncture",
        "cannot move",
        "can't move",
        "stopped suddenly",
        "vehicle stopped",
    ]

    medium_keywords = [
        "battery",
        "ac not working",
        "air conditioning",
        "check engine",
        "strange noise",
        "noise",
        "starting problem",
        "not starting",
        "rough",
        "stalling",
    ]

    if any(word in text for word in critical_keywords):
        return "CRITICAL"

    if any(word in text for word in high_keywords):
        return "HIGH"

    if any(word in text for word in medium_keywords):
        return "MEDIUM"

    return "LOW"


def build_possible_causes(
    symptom: str,
    dtc_records: list[DTC],
) -> list[str]:

    causes = []

    for dtc in dtc_records:
        if dtc.possible_causes:
            causes.append(dtc.possible_causes)

    text = symptom.lower()

    if not causes:

        if any(
            word in text
            for word in [
                "flat tyre",
                "flat tire",
                "puncture",
                "punctured",
            ]
        ):
            causes = [
                "Possible tyre puncture",
                "Possible air pressure loss",
                "Possible tyre or valve damage",
            ]

        elif any(
            word in text
            for word in [
                "battery",
                "won't start",
                "wont start",
                "not starting",
            ]
        ):
            causes = [
                "Weak or discharged battery",
                "Possible starter or electrical issue",
                "Possible charging-system problem",
            ]

        elif any(
            word in text
            for word in [
                "overheating",
                "overheat",
            ]
        ):
            causes = [
                "Low coolant level",
                "Cooling-system fault",
                "Possible radiator, thermostat or fan problem",
            ]

        elif any(
            word in text
            for word in [
                "brake",
                "brakes",
            ]
        ):
            causes = [
                "Brake component wear",
                "Possible hydraulic or mechanical brake problem",
                "Brake inspection required",
            ]

        else:
            causes = [
                "Cause cannot be confirmed from symptoms alone",
                "Vehicle inspection is recommended",
            ]

    return causes[:5]


def build_safety_advice(
    symptom: str,
    severity: str,
) -> list[str]:

    text = symptom.lower()

    advice = []

    dangerous = (
        severity in ["HIGH", "CRITICAL"]
        or any(
            word in text
            for word in [
                "brake failure",
                "no brakes",
                "steering failure",
                "fuel leak",
                "fire",
                "accident",
                "overheating",
                "tyre burst",
                "tire burst",
            ]
        )
    )

    if dangerous:
        advice.append(
            "Move the vehicle to a safe location if it can be done safely."
        )

        advice.append(
            "Use hazard lights and stay away from moving traffic."
        )

        advice.append(
            "Do not continue driving if doing so could be unsafe."
        )

    else:
        advice.append(
            "If the vehicle is unsafe to drive, stop in a safe location."
        )

    if "overheat" in text or "overheating" in text:
        advice.append(
            "Do not open the radiator or coolant reservoir while the engine is hot."
        )

    if "fuel leak" in text or "petrol leak" in text or "diesel leak" in text:
        advice.append(
            "Avoid flames, sparks and smoking near the vehicle."
        )

    if "brake" in text:
        advice.append(
            "Avoid driving the vehicle if braking performance is significantly reduced."
        )

    if "flat tyre" in text or "flat tire" in text or "puncture" in text:
        advice.append(
            "Do not drive at normal speed on a severely damaged or flat tyre."
        )

    return advice[:6]


def build_recommended_action(
    symptom: str,
    category: str,
    severity: str,
) -> str:

    text = symptom.lower()

    if severity == "CRITICAL":
        return (
            "Stop driving if safe to do so and request immediate roadside "
            "assistance or emergency support as appropriate."
        )

    if category == "Tyre":
        return (
            "Request tyre assistance for inspection, puncture repair or "
            "replacement."
        )

    if category == "Battery":
        return (
            "Request battery/roadside assistance for battery testing, "
            "jump-starting or replacement."
        )

    if category == "Brake":
        return (
            "Request a brake inspection. Avoid driving if braking performance "
            "is unsafe."
        )

    if category == "Cooling":
        return (
            "Allow the engine to cool safely and request cooling-system "
            "inspection."
        )

    if category == "Steering":
        return (
            "Avoid driving if steering control is compromised and request "
            "roadside assistance."
        )

    if category == "Transmission":
        return (
            "Request transmission/clutch inspection rather than continuing "
            "to operate the vehicle if movement is abnormal."
        )

    if category == "Accident":
        return (
            "Move to safety if possible, document the situation and request "
            "roadside/towing assistance when required."
        )

    if category == "Lockout":
        return (
            "Request vehicle lockout assistance. Do not attempt unsafe forced "
            "entry."
        )

    if category == "Towing":
        return (
            "Request a suitable towing/service vehicle and avoid attempting "
            "to move an unsafe or immobilized vehicle yourself."
        )

    if "not starting" in text or "won't start" in text or "wont start" in text:
        return (
            "Request roadside assistance for battery, starter, fuel and "
            "ignition-system inspection."
        )

    return (
        "Request roadside assistance for professional vehicle inspection "
        "and diagnosis."
    )


def build_diagnosis(
    symptom: str,
    category: str,
    severity: str,
    dtc_records: list[DTC],
) -> str:

    if dtc_records:
        descriptions = [
            dtc.description
            for dtc in dtc_records
            if dtc.description
        ]

        if descriptions:
            return "Possible issue: " + "; ".join(descriptions[:3])

    if category == "Tyre":
        return (
            "The symptoms indicate a possible tyre or wheel-related "
            "roadside problem."
        )

    if category == "Battery":
        return (
            "The symptoms indicate a possible battery, starting or "
            "vehicle electrical problem."
        )

    if category == "Brake":
        return (
            "The symptoms indicate a possible braking-system problem "
            "requiring inspection."
        )

    if category == "Cooling":
        return (
            "The symptoms indicate a possible engine cooling-system problem."
        )

    if category == "Steering":
        return (
            "The symptoms indicate a possible steering or steering-control "
            "problem."
        )

    if category == "Transmission":
        return (
            "The symptoms indicate a possible transmission or clutch-related "
            "problem."
        )

    if category == "Accident":
        return (
            "The vehicle may require post-accident inspection and roadside "
            "assistance."
        )

    return (
        "The reported symptoms require further vehicle inspection. "
        "The exact physical fault cannot be confirmed from text alone."
    )


def determine_confidence(
    ai_source: str,
    dtc_records: list[DTC],
    symptom: str,
) -> float:

    if ai_source.startswith("Gemini AI"):
        if dtc_records:
            return 85.0

        if len(symptom.strip()) >= 20:
            return 75.0

        return 65.0

    if dtc_records:
        return 60.0

    if len(symptom.strip()) >= 20:
        return 55.0

    return 40.0


# ============================================================
# AI SYMPTOM DIAGNOSIS
# ============================================================

@app.post(
    "/ai/diagnose",
    response_model=SymptomAnalysisResponse,
)
async def diagnose_symptoms(
    payload: SymptomAnalysisRequest,
    db: AsyncSession = Depends(get_db),
):
    symptom = payload.symptom_description.strip()

    if not symptom:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Please describe the vehicle problem.",
        )

    diagnosis_data, ai_source = await run_in_threadpool(
        analyze_symptoms_with_gemini,
        symptom,
    )

    if not isinstance(diagnosis_data, dict):
        diagnosis_data = {}

    dtc_codes = diagnosis_data.get("dtc_codes", [])
    if not isinstance(dtc_codes, list):
        dtc_codes = []

    dtc_codes = list(dict.fromkeys(
        str(code).strip().upper()
        for code in dtc_codes
        if str(code).strip()
    ))

    # Offline safety net: when Gemini is unavailable and the local fallback
    # does not return a DTC, add a conservative possible battery-voltage code
    # for a clear dead-battery/no-start report. This is NOT a confirmed code.
    battery_text = symptom.lower()
    battery_no_start = (
        any(word in battery_text for word in [
            "battery", "dead battery", "battery dead"
        ])
        and any(word in battery_text for word in [
            "won't start", "wont start", "will not start", "not start",
            "no start", "engine will not start", "engine won't start"
        ])
    )

    if not dtc_codes and battery_no_start:
        dtc_codes = ["P0562"]

    if dtc_codes:
        result = await db.execute(
            select(DTC).where(DTC.code.in_(dtc_codes))
        )
        dtc_records = result.scalars().all()
    else:
        dtc_records = []

    detected_dtcs = [
        DTCInfo(
            code=dtc.code,
            description=dtc.description,
            severity=dtc.severity,
            possible_causes=dtc.possible_causes,
            recommended_action=dtc.recommended_action,
        )
        for dtc in dtc_records
    ]

    problem_understood = str(
        diagnosis_data.get(
            "problem_understood",
            "Vehicle problem requires further assessment.",
        )
    ).strip()

    suggested_category = str(
        diagnosis_data.get("service_category", "General Repair")
    ).strip()

    severity = str(
        diagnosis_data.get("severity", "MEDIUM")
    ).strip().upper()

    if severity not in {"LOW", "MEDIUM", "HIGH", "CRITICAL"}:
        severity = "MEDIUM"

    try:
        confidence = float(diagnosis_data.get("confidence", 50))
    except (TypeError, ValueError):
        confidence = 50.0

    confidence = max(0.0, min(confidence, 100.0))

    diagnosis = str(
        diagnosis_data.get(
            "diagnosis",
            "Further vehicle inspection is required.",
        )
    ).strip()

    possible_causes = diagnosis_data.get("possible_causes", [])
    if not isinstance(possible_causes, list):
        possible_causes = [str(possible_causes)]

    possible_causes = [
        str(item).strip()
        for item in possible_causes
        if str(item).strip()
    ][:6]

    safety_advice = diagnosis_data.get("safety_advice", [])
    if not isinstance(safety_advice, list):
        safety_advice = [str(safety_advice)]

    safety_advice = [
        str(item).strip()
        for item in safety_advice
        if str(item).strip()
    ][:6]

    recommended_action = str(
        diagnosis_data.get(
            "recommended_action",
            "Request roadside assistance for professional inspection.",
        )
    ).strip()

    roadside_assistance_required = bool(
        diagnosis_data.get("roadside_assistance_required", True)
    )

    towing_recommended = bool(
        diagnosis_data.get("towing_recommended", False)
    )

    # Safety overrides.
    if severity == "CRITICAL":
        roadside_assistance_required = True
        towing_recommended = True

    if suggested_category in {
        "Brake",
        "Steering",
        "Accident",
        "Towing",
    }:
        roadside_assistance_required = True

    # Also expose valid AI-identified DTCs that are not yet in PostgreSQL.
    # We do not invent technical descriptions for these codes.
    detected_database_codes = {
        dtc.code.upper() for dtc in dtc_records
    }

    for code in dtc_codes:
        if code not in detected_database_codes:
            detected_dtcs.append(
                DTCInfo(
                    code=code,
                    description=(
                        "AI-identified DTC; detailed local database "
                        "information is unavailable."
                    ),
                    severity=severity,
                    possible_causes=(
                        "Further diagnostic scanning is recommended to "
                        "confirm this code and its cause."
                    ),
                    recommended_action=(
                        "Use an OBD diagnostic scanner and have a qualified "
                        "technician verify the code before repair."
                    ),
                )
            )

    missing_dtc_codes = [
        code for code in dtc_codes
        if code not in detected_database_codes
    ]

    if missing_dtc_codes:
        possible_causes.append(
            "AI identified additional DTC code(s) that are not yet "
            "present in the local DTC database: "
            + ", ".join(missing_dtc_codes)
        )
        possible_causes = possible_causes[:6]

    if dtc_codes:
        dtc_text = ", ".join(dtc_codes)
        summary = (
            f"{problem_understood} "
            f"Category: {suggested_category}. "
            f"Severity: {severity}. "
            f"Potential DTCs: {dtc_text}. "
            f"Roadside assistance: "
            f"{'Yes' if roadside_assistance_required else 'No'}."
        )
    else:
        summary = (
            f"{problem_understood} "
            f"Category: {suggested_category}. "
            f"Severity: {severity}. "
            f"No directly applicable DTC was identified. "
            f"Roadside assistance: "
            f"{'Yes' if roadside_assistance_required else 'No'}."
        )

    return SymptomAnalysisResponse(
        symptom_description=symptom,
        ai_source=ai_source,
        problem_understood=problem_understood,
        suggested_category=suggested_category,
        severity=severity,
        confidence=confidence,
        diagnosis=diagnosis,
        possible_causes=possible_causes,
        safety_advice=safety_advice,
        recommended_action=recommended_action,
        roadside_assistance_required=roadside_assistance_required,
        towing_recommended=towing_recommended,
        detected_dtcs=detected_dtcs,
        summary=summary,
    )


# ============================================================
# MECHANIC / SERVICE PROVIDERS
# ============================================================

@app.get(
    "/mechanics/",
    response_model=List[MechanicResponse],
)
async def get_mechanics(
    db: AsyncSession = Depends(get_db),
):

    result = await db.execute(
        select(Mechanic)
    )

    mechanics = result.scalars().all()

    return mechanics


# ============================================================
# CREATE MECHANIC PROFILE
# ============================================================

@app.post(
    "/mechanics/",
    response_model=MechanicResponse,
)
async def create_mechanic(
    mechanic_data: MechanicCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_role("MECHANIC")),
):

    # --------------------------------------------------------
    # Securely link the profile to authenticated mechanic
    # --------------------------------------------------------

    if (
        mechanic_data.user_id is not None
        and mechanic_data.user_id != current_user.id
    ):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=(
                "You can create a mechanic profile only "
                "for your own account"
            ),
        )

    linked_user_id = current_user.id

    if mechanic_data.user_id is not None:

        user = await db.scalar(
            select(User).where(
                User.id == mechanic_data.user_id
            )
        )

        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Linked user not found",
            )

        if user.role.upper() != "MECHANIC":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Linked user must have MECHANIC role",
            )

        existing_profile = await db.scalar(
            select(Mechanic).where(
                Mechanic.user_id == mechanic_data.user_id
            )
        )

        if existing_profile:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=(
                    "This user already has a mechanic profile"
                ),
            )

    mechanic = Mechanic(
        user_id=linked_user_id,
        name=mechanic_data.name,
        phone_number=mechanic_data.phone_number,
        service_categories=(
            mechanic_data.service_categories
        ),
        supported_vehicle_types=(
            mechanic_data.supported_vehicle_types
        ),
        latitude=mechanic_data.latitude,
        longitude=mechanic_data.longitude,
        is_available=mechanic_data.is_available,
        rating=mechanic_data.rating,
        experience_years=mechanic_data.experience_years,
        status=mechanic_data.status,
    )

    db.add(mechanic)

    await db.commit()
    await db.refresh(mechanic)

    return mechanic


# ============================================================
# ASSISTANCE REQUESTS - GET
# ============================================================

@app.get(
    "/assistance/",
    response_model=List[AssistanceRequestResponse],
)
async def get_assistance_requests(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):

    # Drivers see only their own requests.
    if current_user.role.upper() == "DRIVER":

        result = await db.execute(
            select(AssistanceRequest).where(
                AssistanceRequest.driver_user_id
                == current_user.id
            )
        )

    # Mechanics see pending requests and their own assigned requests.
    elif current_user.role.upper() == "MECHANIC":

        mechanic = await get_current_mechanic(
            current_user,
            db,
        )

        result = await db.execute(
            select(AssistanceRequest).where(
                (AssistanceRequest.status == "PENDING")
                | (
                    AssistanceRequest.mechanic_id
                    == mechanic.id
                )
            )
        )

    else:

        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=(
                "Only DRIVER and MECHANIC roles can "
                "access assistance requests"
            ),
        )

    requests = result.scalars().all()

    return requests


# ============================================================
# ASSISTANCE REQUESTS - CREATE
# ============================================================

@app.post(
    "/assistance/",
    response_model=AssistanceRequestResponse,
)
async def create_assistance_request(
    request_data: AssistanceRequestCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(
        require_role("DRIVER")
    ),
):
    # Do not create another request while this driver has an active one.
    active_request = await db.scalar(
        select(AssistanceRequest).where(
            AssistanceRequest.driver_user_id == current_user.id,
            AssistanceRequest.status.in_(
                ["PENDING", "ACCEPTED", "IN_PROGRESS"]
            ),
        )
    )

    if active_request:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=(
                "You already have an active assistance request. "
                "Please wait until it is completed before creating "
                "another request."
            ),
        )

    request = AssistanceRequest(
        driver_user_id=current_user.id,
        driver_name=request_data.driver_name,
        phone_number=request_data.phone_number,
        vehicle_type=request_data.vehicle_type,
        vehicle_info=request_data.vehicle_info,
        category=request_data.category,
        issue_description=request_data.issue_description,
        latitude=request_data.latitude,
        longitude=request_data.longitude,
        status="PENDING",
    )

    db.add(request)
    await db.commit()
    await db.refresh(request)

    return request


# ============================================================
# DISTANCE CALCULATION
# ============================================================

def calculate_distance(
    lat1: float,
    lon1: float,
    lat2: float,
    lon2: float,
) -> float:

    earth_radius = 6371.0

    lat1_rad = radians(lat1)
    lat2_rad = radians(lat2)

    delta_lat = radians(
        lat2 - lat1
    )

    delta_lon = radians(
        lon2 - lon1
    )

    a = (
        sin(delta_lat / 2) ** 2
        + cos(lat1_rad)
        * cos(lat2_rad)
        * sin(delta_lon / 2) ** 2
    )

    c = 2 * atan2(
        sqrt(a),
        sqrt(1 - a),
    )

    return earth_radius * c


# ============================================================
# DISTANCE DISPLAY FORMAT
# ============================================================

def format_distance(
    distance_km: float,
) -> str:

    if distance_km < 1.0:
        distance_meters = round(
            distance_km * 1000
        )

        return f"{distance_meters} m away"

    return f"{distance_km:.1f} km away"


# ============================================================
# VEHICLE TYPE NORMALIZATION
# ============================================================

def normalize_vehicle_type(
    vehicle_type: str,
) -> str:

    value = vehicle_type.strip().lower()

    vehicle_aliases = {
        "motorcycle": "bike",
        "motorbike": "bike",
        "2-wheeler": "bike",
        "2 wheeler": "bike",
        "two-wheeler": "bike",
        "two wheeler": "bike",
    }

    return vehicle_aliases.get(
        value,
        value,
    )


# ============================================================
# AI-BASED MECHANIC MATCHING
# ============================================================

@app.post(
    "/assistance/match",
    response_model=MechanicMatchResult,
)
async def match_mechanics(
    request_data: AssistanceRequestCreate,
    db: AsyncSession = Depends(get_db),
):

    requested_category = (
        request_data.category
        .strip()
        .lower()
    )

    requested_vehicle = normalize_vehicle_type(
        request_data.vehicle_type
    )

    result = await db.execute(
        select(Mechanic).where(
            Mechanic.is_available == True
        )
    )

    mechanics = result.scalars().all()

    matches = []

    for mechanic in mechanics:

        supported_categories = {
            item.strip().lower()
            for item in mechanic.service_categories.split(",")
        }

        supported_vehicles = {
            normalize_vehicle_type(item)
            for item in mechanic.supported_vehicle_types.split(",")
        }

        supports_category = (
            requested_category
            in supported_categories
        )

        supports_vehicle = (
            requested_vehicle
            in supported_vehicles
        )

        if not supports_category:
            continue

        if not supports_vehicle:
            continue

        distance = calculate_distance(
            request_data.latitude,
            request_data.longitude,
            mechanic.latitude,
            mechanic.longitude,
        )

        estimated_eta = max(
            5,
            int(
                round(distance * 10)
            ),
        )

        # ----------------------------------------------------
        # AI SCORING COMPONENTS
        # ----------------------------------------------------

        distance_score = 1 / (
            1 + distance
        )

        rating_score = max(
            0.0,
            min(
                mechanic.rating / 5.0,
                1.0,
            ),
        )

        experience_score = (
            mechanic.experience_years
            / (
                mechanic.experience_years
                + 5.0
            )
        )

        eta_score = 1 / (
            1 + estimated_eta
        )

        ai_score = (
            distance_score
            + rating_score
            + experience_score
            + eta_score
        ) / 4.0

        ai_score = ai_score * 100

        matches.append(
            MechanicMatchResponse(
                mechanic_id=mechanic.id,
                mechanic_name=mechanic.name,
                distance_km=round(
                    distance,
                    2,
                ),
                distance_display=format_distance(
                    distance
                ),
                estimated_eta_minutes=estimated_eta,
                rating=mechanic.rating,
                experience_years=(
                    mechanic.experience_years
                ),
                ai_score=round(
                    ai_score,
                    2,
                ),
            )
        )

    # --------------------------------------------------------
    # SORT BEST MATCH FIRST
    # --------------------------------------------------------

    matches.sort(
        key=lambda item: item.ai_score,
        reverse=True,
    )

    return MechanicMatchResult(
        recommendation_method=(
            "Actual-value-based mechanic matching using "
            "distance, rating, experience and ETA"
        ),
        matches=matches,
    )


# ============================================================
# GET LOGGED-IN MECHANIC PROFILE
# ============================================================

async def get_current_mechanic(
    current_user: User,
    db: AsyncSession,
) -> Mechanic:

    if current_user.role.upper() != "MECHANIC":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="MECHANIC role required",
        )

    mechanic = await db.scalar(
        select(Mechanic).where(
            Mechanic.user_id
            == current_user.id
        )
    )

    if not mechanic:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=(
                "Mechanic profile not found "
                "for the logged-in user"
            ),
        )

    return mechanic


# ============================================================
# ACCEPT ASSISTANCE REQUEST
# ============================================================

@app.post(
    "/assistance/{request_id}/accept"
)
async def accept_assistance_request(
    request_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(
        require_role("MECHANIC")
    ),
):

    request = await db.scalar(
        select(AssistanceRequest)
        .where(
            AssistanceRequest.id
            == request_id
        )
        .with_for_update()
    )

    if not request:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Assistance request not found",
        )

    if request.status != "PENDING":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                "Request cannot be accepted "
                "because its status is "
                f"{request.status}"
            ),
        )

    mechanic = await get_current_mechanic(
        current_user,
        db,
    )

    if not mechanic.is_available:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Mechanic is currently unavailable",
        )

    request.mechanic_id = mechanic.id
    request.status = "ACCEPTED"

    mechanic.is_available = False
    mechanic.status = "BUSY"

    await db.commit()

    return {
        "message": "Assistance request accepted",
        "request_id": request.id,
        "status": request.status,
        "mechanic_id": mechanic.id,
        "mechanic_name": mechanic.name,
    }


# ============================================================
# START ASSISTANCE REQUEST
# ============================================================

@app.post(
    "/assistance/{request_id}/start"
)
async def start_assistance_request(
    request_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(
        require_role("MECHANIC")
    ),
):

    request = await db.scalar(
        select(AssistanceRequest).where(
            AssistanceRequest.id
            == request_id
        )
    )

    if not request:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Assistance request not found",
        )

    mechanic = await get_current_mechanic(
        current_user,
        db,
    )

    if request.mechanic_id != mechanic.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=(
                "You are not authorized to "
                "manage this assistance request"
            ),
        )

    if request.status != "ACCEPTED":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                "Request cannot be started "
                "because its status is "
                f"{request.status}"
            ),
        )

    request.status = "IN_PROGRESS"

    await db.commit()

    return {
        "message": "Assistance request started",
        "request_id": request.id,
        "status": request.status,
        "mechanic_id": mechanic.id,
        "mechanic_name": mechanic.name,
    }


# ============================================================
# COMPLETE ASSISTANCE REQUEST
# ============================================================

@app.post(
    "/assistance/{request_id}/complete"
)
async def complete_assistance_request(
    request_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(
        require_role("MECHANIC")
    ),
):

    request = await db.scalar(
        select(AssistanceRequest).where(
            AssistanceRequest.id
            == request_id
        )
    )

    if not request:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Assistance request not found",
        )

    mechanic = await get_current_mechanic(
        current_user,
        db,
    )

    if request.mechanic_id != mechanic.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=(
                "You are not authorized to "
                "manage this assistance request"
            ),
        )

    if request.status != "IN_PROGRESS":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                "Request cannot be completed "
                "because its status is "
                f"{request.status}"
            ),
        )

    request.status = "COMPLETED"

    # Make mechanic available for new requests.
    mechanic.is_available = True
    mechanic.status = "AVAILABLE"

    await db.commit()

    return {
        "message": "Assistance request completed",
        "request_id": request.id,
        "status": request.status,
        "mechanic_id": mechanic.id,
        "mechanic_name": mechanic.name,
    }