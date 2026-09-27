from sqlalchemy import (
    Column,
    Integer,
    String,
    Float,
    Boolean,
    DateTime,
    Text,
    ForeignKey,
)
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from app.database import Base


# =========================
# USER MODEL
# =========================

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)

    email = Column(
        String(255),
        unique=True,
        index=True,
        nullable=False,
    )

    hashed_password = Column(
        String(255),
        nullable=False,
    )

    full_name = Column(
        String(100),
        nullable=False,
    )

    role = Column(
        String(20),
        nullable=False,
        default="DRIVER",
    )

    is_active = Column(
        Boolean,
        default=True,
        nullable=False,
    )

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )

    # One User -> One Mechanic Profile
    mechanic_profile = relationship(
        "Mechanic",
        back_populates="user",
        uselist=False,
    )

    # One Driver User -> Many Assistance Requests
    assistance_requests = relationship(
        "AssistanceRequest",
        back_populates="driver",
        foreign_keys="AssistanceRequest.driver_user_id",
    )


# =========================
# DTC MODEL
# =========================

class DTC(Base):
    __tablename__ = "dtc_codes"

    id = Column(
        Integer,
        primary_key=True,
        index=True,
    )

    code = Column(
        String(10),
        unique=True,
        index=True,
        nullable=False,
    )

    description = Column(
        Text,
        nullable=False,
    )

    severity = Column(
        String(20),
        nullable=False,
    )

    possible_causes = Column(
        Text,
        nullable=False,
    )

    recommended_action = Column(
        Text,
        nullable=False,
    )


# =========================
# MECHANIC MODEL
# =========================

class Mechanic(Base):
    __tablename__ = "mechanics"

    id = Column(
        Integer,
        primary_key=True,
        index=True,
    )

    # Link Mechanic Profile -> User Account
    user_id = Column(
        Integer,
        ForeignKey("users.id"),
        nullable=True,
        unique=True,
        index=True,
    )

    name = Column(
        String(100),
        nullable=False,
    )

    phone_number = Column(
        String(20),
        nullable=False,
    )

    service_categories = Column(
        Text,
        nullable=False,
    )

    supported_vehicle_types = Column(
        Text,
        nullable=False,
    )

    latitude = Column(
        Float,
        nullable=False,
    )

    longitude = Column(
        Float,
        nullable=False,
    )

    is_available = Column(
        Boolean,
        default=True,
        nullable=False,
    )

    rating = Column(
        Float,
        default=5.0,
        nullable=False,
    )

    experience_years = Column(
        Integer,
        default=1,
        nullable=False,
    )

    status = Column(
        String(20),
        default="AVAILABLE",
        nullable=False,
    )

    # User <-> Mechanic relationship
    user = relationship(
        "User",
        back_populates="mechanic_profile",
    )

    # Mechanic -> Assistance Requests
    assigned_requests = relationship(
        "AssistanceRequest",
        back_populates="mechanic",
    )


# =========================
# ASSISTANCE REQUEST MODEL
# =========================

class AssistanceRequest(Base):
    __tablename__ = "assistance_requests"

    id = Column(
        Integer,
        primary_key=True,
        index=True,
    )

    # Link every request to the authenticated driver
    # Nullable for now so existing database rows remain valid.
    driver_user_id = Column(
        Integer,
        ForeignKey("users.id"),
        nullable=True,
        index=True,
    )

    driver_name = Column(
        String(100),
        nullable=False,
    )

    phone_number = Column(
        String(20),
        nullable=False,
    )

    vehicle_type = Column(
        String(50),
        nullable=False,
        default="Car",
    )

    vehicle_info = Column(
        String(100),
        nullable=False,
    )

    category = Column(
        String(50),
        nullable=False,
        default="General Repair",
    )

    issue_description = Column(
        Text,
        nullable=False,
    )

    latitude = Column(
        Float,
        nullable=False,
    )

    longitude = Column(
        Float,
        nullable=False,
    )

    status = Column(
        String(20),
        default="PENDING",
        nullable=False,
    )

    # Assigned mechanic
    mechanic_id = Column(
        Integer,
        ForeignKey("mechanics.id"),
        nullable=True,
        index=True,
    )

    # Driver -> Assistance Requests relationship
    driver = relationship(
        "User",
        back_populates="assistance_requests",
        foreign_keys=[driver_user_id],
    )

    # Mechanic -> Assistance Request relationship
    mechanic = relationship(
        "Mechanic",
        back_populates="assigned_requests",
    )

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )
