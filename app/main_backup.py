from contextlib import asynccontextmanager
from math import radians, sin, cos, sqrt, atan2
from typing import List

from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.concurrency import run_in_threadpool
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

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
# ROOT
# ============================================================

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

    # --------------------------------------------------------
    # 1. Analyze driver's symptoms using Gemini AI
    # --------------------------------------------------------

    dtc_codes, ai_source = await run_in_threadpool(
        analyze_symptoms_with_gemini,
        payload.symptom_description,
    )

    # --------------------------------------------------------
    # 2. Query matching DTC records from PostgreSQL
    # --------------------------------------------------------

    if dtc_codes:

        result = await db.execute(
            select(DTC).where(
                DTC.code.in_(dtc_codes)
            )
        )

        dtc_records = result.scalars().all()

    else:

        dtc_records = []

    # --------------------------------------------------------
    # 3. Convert database DTC records
    # --------------------------------------------------------

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

    # --------------------------------------------------------
    # 4. Determine recommended service category
    # --------------------------------------------------------

    detected_codes = {
        dtc.code.upper()
        for dtc in dtc_records
    }

    # Explicit priority prevents the category from depending on
    # the order in which DTC records are returned.
    category_priority = [
        ("Fuel", {"P0455", "P0171"}),
        ("Exhaust", {"P0420"}),
        ("Engine", {"P0128", "P0300"}),
    ]

    suggested_category = next(
        (
            category
            for category, codes in category_priority
            if detected_codes & codes
        ),
        "Engine",
    )

    # --------------------------------------------------------
    # 5. Generate summary
    # --------------------------------------------------------

    summary = (
        f"Analysis identified "
        f"{len(detected_dtcs)} potential "
        f"diagnostic trouble code(s). "
        f"Recommended primary service category: "
        f"{suggested_category}."
    )

    # --------------------------------------------------------
    # 6. Return complete AI diagnosis response
    # --------------------------------------------------------

    return SymptomAnalysisResponse(
        symptom_description=payload.symptom_description,
        ai_source=ai_source,
        detected_dtcs=detected_dtcs,
        suggested_category=suggested_category,
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
    # Securely link the profile to the authenticated mechanic
    # --------------------------------------------------------

    if mechanic_data.user_id is not None and mechanic_data.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You can create a mechanic profile only for your own account",
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
                detail=(
                    "Linked user must have "
                    "MECHANIC role"
                ),
            )

        existing_profile = await db.scalar(
            select(Mechanic).where(
                Mechanic.user_id ==
                mechanic_data.user_id
            )
        )

        if existing_profile:

            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=(
                    "This user already has "
                    "a mechanic profile"
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

        is_available=(
            mechanic_data.is_available
        ),

        rating=mechanic_data.rating,

        experience_years=(
            mechanic_data.experience_years
        ),

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

    # Drivers can see only their own assistance requests.
    if current_user.role.upper() == "DRIVER":

        result = await db.execute(
            select(AssistanceRequest).where(
                AssistanceRequest.driver_user_id == current_user.id
            )
        )

    # Mechanics can see pending requests and requests already
    # assigned to their own mechanic profile.
    elif current_user.role.upper() == "MECHANIC":

        mechanic = await get_current_mechanic(
            current_user,
            db,
        )

        result = await db.execute(
            select(AssistanceRequest).where(
                (AssistanceRequest.status == "PENDING")
                | (AssistanceRequest.mechanic_id == mechanic.id)
            )
        )

    else:

        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=(
                "Only DRIVER and MECHANIC roles can access "
                "assistance requests"
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

    request = AssistanceRequest(

        # Link the request to the authenticated driver
        driver_user_id=current_user.id,

        driver_name=request_data.driver_name,

        phone_number=request_data.phone_number,

        vehicle_type=request_data.vehicle_type,

        vehicle_info=request_data.vehicle_info,

        category=request_data.category,

        issue_description=(
            request_data.issue_description
        ),

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

def format_distance(distance_km: float) -> str:
    """
    Format distance for the user interface.

    Below 1 km:
        Display in meters, e.g. "200 m away"

    1 km or more:
        Display in kilometers, e.g. "1.2 km away"
    """

    if distance_km < 1.0:
        distance_meters = round(distance_km * 1000)
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

    requested_vehicle = (
        normalize_vehicle_type(
            request_data.vehicle_type
        )
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

            for item in
            mechanic.service_categories.split(",")

        }

        supported_vehicles = {

            normalize_vehicle_type(item)

            for item in
            mechanic.supported_vehicle_types.split(",")

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
        # Actual-value-based matching:
        #   distance       -> actual km, closer is better
        #   rating         -> actual rating out of 5
        #   experience     -> actual years
        #   ETA            -> actual estimated minutes, lower is better
        #
        # No fixed 40/25/20/15 percentage weights are used.
        # The values are normalized only to make different units
        # mathematically comparable, then treated equally.
        # ----------------------------------------------------

        # Closer mechanic = higher distance score.
        distance_score = 1 / (1 + distance)

        # Rating is directly based on the mechanic's rating out of 5.
        rating_score = max(
            0.0,
            min(mechanic.rating / 5.0, 1.0),
        )

        # More experience = higher score, with diminishing returns.
        experience_score = (
            mechanic.experience_years
            / (mechanic.experience_years + 5.0)
        )

        # Lower ETA = higher score.
        eta_score = 1 / (1 + estimated_eta)

        # Equal mathematical treatment of the four actual values.
        ai_score = (
            distance_score
            + rating_score
            + experience_score
            + eta_score
        ) / 4.0

        # Display score on a 0-100 scale.
        # This is NOT a percentage weight.
        ai_score = ai_score * 100

        # ----------------------------------------------------
        # APPEND MATCH RESULT
        # ----------------------------------------------------

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

                estimated_eta_minutes=(
                    estimated_eta
                ),

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

        key=lambda item:
        item.ai_score,

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

            Mechanic.user_id ==
            current_user.id

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

    # Lock the request row so two mechanics cannot accept it at the same time.
    # PostgreSQL FOR UPDATE holds the row lock until this transaction commits.
    request = await db.scalar(

        select(AssistanceRequest)
        .where(AssistanceRequest.id == request_id)
        .with_for_update()

    )

    if not request:

        raise HTTPException(

            status_code=status.HTTP_404_NOT_FOUND,

            detail=(
                "Assistance request not found"
            ),

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

            detail=(
                "Mechanic is currently unavailable"
            ),

        )

    request.mechanic_id = mechanic.id

    request.status = "ACCEPTED"

    mechanic.is_available = False

    mechanic.status = "BUSY"

    await db.commit()

    return {

        "message":
            "Assistance request accepted",

        "request_id":
            request.id,

        "status":
            request.status,

        "mechanic_id":
            mechanic.id,

        "mechanic_name":
            mechanic.name,

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

            AssistanceRequest.id ==
            request_id

        )

    )

    if not request:

        raise HTTPException(

            status_code=status.HTTP_404_NOT_FOUND,

            detail=(
                "Assistance request not found"
            ),

        )

    mechanic = await get_current_mechanic(

        current_user,

        db,

    )

    # --------------------------------------------------------
    # IMPORTANT SECURITY CHECK
    # --------------------------------------------------------

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

        "message":
            "Assistance request started",

        "request_id":
            request.id,

        "status":
            request.status,

        "mechanic_id":
            mechanic.id,

        "mechanic_name":
            mechanic.name,

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

            AssistanceRequest.id ==
            request_id

        )

    )

    if not request:

        raise HTTPException(

            status_code=status.HTTP_404_NOT_FOUND,

            detail=(
                "Assistance request not found"
            ),

        )

    mechanic = await get_current_mechanic(

        current_user,

        db,

    )

    # --------------------------------------------------------
    # IMPORTANT SECURITY CHECK
    # --------------------------------------------------------

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

    # --------------------------------------------------------
    # Make mechanic available for new requests
    # --------------------------------------------------------

    mechanic.is_available = True

    mechanic.status = "AVAILABLE"

    await db.commit()

    return {

        "message":
            "Assistance request completed",

        "request_id":
            request.id,

        "status":
            request.status,

        "mechanic_id":
            mechanic.id,

        "mechanic_name":
            mechanic.name,

    }