from datetime import datetime
from pydantic import BaseModel, ConfigDict, EmailStr


# ============================================================
# AUTHENTICATION SCHEMAS
# ============================================================

class UserCreate(BaseModel):
    email: EmailStr
    password: str
    full_name: str
    role: str = "DRIVER"


class UserResponse(BaseModel):
    id: int
    email: EmailStr
    full_name: str
    role: str
    is_active: bool
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class Token(BaseModel):
    access_token: str
    token_type: str


# ============================================================
# DTC SCHEMAS
# ============================================================

class DTCCreate(BaseModel):
    code: str
    description: str
    severity: str
    possible_causes: str
    recommended_action: str


class DTCResponse(BaseModel):
    id: int
    code: str
    description: str
    severity: str
    possible_causes: str
    recommended_action: str

    model_config = ConfigDict(from_attributes=True)


# ============================================================
# MECHANIC SCHEMAS
# ============================================================

class MechanicCreate(BaseModel):
    user_id: int | None = None
    name: str
    phone_number: str
    service_categories: str
    supported_vehicle_types: str
    latitude: float
    longitude: float
    is_available: bool = True
    rating: float = 5.0
    experience_years: int = 1
    status: str = "AVAILABLE"


class MechanicResponse(BaseModel):
    id: int
    user_id: int | None = None
    name: str
    phone_number: str
    service_categories: str
    supported_vehicle_types: str
    latitude: float
    longitude: float
    is_available: bool
    rating: float
    experience_years: int
    status: str

    model_config = ConfigDict(from_attributes=True)


# ============================================================
# ASSISTANCE REQUEST SCHEMAS
# ============================================================

class AssistanceRequestCreate(BaseModel):
    driver_name: str
    phone_number: str
    vehicle_type: str = "Car"
    vehicle_info: str
    category: str = "General Repair"
    issue_description: str
    latitude: float
    longitude: float


class AssistanceRequestResponse(BaseModel):
    id: int
    driver_name: str
    phone_number: str
    vehicle_type: str
    vehicle_info: str
    category: str
    issue_description: str
    latitude: float
    longitude: float
    status: str
    mechanic_id: int | None = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


# ============================================================
# MECHANIC MATCHING SCHEMAS
# ============================================================

class MechanicMatchResponse(BaseModel):
    mechanic_id: int
    mechanic_name: str

    # Numeric distance retained for calculations.
    distance_km: float

    # User-friendly distance for the mobile/web UI.
    # < 1 km  -> "200 m away"
    # >= 1 km -> "1.2 km away"
    distance_display: str

    estimated_eta_minutes: int
    rating: float
    experience_years: int
    ai_score: float


class MechanicMatchResult(BaseModel):
    recommendation_method: str
    matches: list[MechanicMatchResponse]


# ============================================================
# AI DIAGNOSIS SCHEMAS
# ============================================================

class SymptomAnalysisRequest(BaseModel):
    symptom_description: str
    vehicle_type: str | None = None


class DTCInfo(BaseModel):
    code: str
    description: str
    severity: str
    possible_causes: str
    recommended_action: str


class AIDiagnosisResponse(BaseModel):
    """
    Complete AI-powered vehicle diagnosis response.

    The system supports both:
    1. Problems that have applicable OBD-II DTCs.
    2. Mechanical/roadside problems where no DTC applies.
    """

    # Original driver description.
    symptom_description: str

    # Identifies whether Gemini or fallback logic produced
    # the diagnosis.
    ai_source: str

    # AI interpretation of the driver's problem.
    problem_understood: str

    # Main service category required.
    suggested_category: str

    # LOW / MEDIUM / HIGH / CRITICAL
    severity: str

    # AI confidence from 0 to 100.
    confidence: float

    # Main diagnostic explanation.
    diagnosis: str

    # Possible causes identified by the AI.
    possible_causes: list[str]

    # Immediate safety recommendations.
    safety_advice: list[str]

    # Recommended action for the driver.
    recommended_action: str

    # Whether roadside assistance is required.
    roadside_assistance_required: bool

    # Whether towing should be considered.
    towing_recommended: bool

    # Applicable DTC information.
    #
    # This can legitimately be an empty list for problems
    # such as a flat tyre, physical damage, lockout, etc.
    detected_dtcs: list[DTCInfo]

    # Human-readable overall summary.
    summary: str


# ============================================================
# BACKWARD COMPATIBILITY
# ============================================================

# Existing main.py code may still refer to
# SymptomAnalysisResponse.
#
# Keeping this alias prevents import errors while we upgrade
# the /ai/diagnose endpoint.
SymptomAnalysisResponse = AIDiagnosisResponse