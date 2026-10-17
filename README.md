# AI Vehicle Breakdown Assistance Platform

A production-grade, two-app roadside assistance and dispatch system powered by a shared FastAPI backend, Google Gemini AI vehicle diagnosis, and Flutter Android/cross-platform client applications.

---

## 1. System Architecture & Platform Overview

The platform operates on a **dedicated two-app model** with a centralized asynchronous REST API backend:

```
                    ┌────────────────────────────┐
                    │      Google Gemini AI      │
                    │   (Automotive Diagnosis)   │
                    └──────────────┬─────────────┘
                                   │
                                   ▼
┌──────────────────┐        ┌──────────────┐        ┌──────────────────┐
│   Customer App   │◄──────►│ FastAPI REST │◄──────►│   Mechanic App   │
│   (`user_app/`)  │  HTTP  │  Backend API │  HTTP  │(`mechanic_app/`) │
│  (Driver Portal) │  JSON  │   (`app/`)   │  JSON  │ (Partner Portal) │
└──────────────────┘        └──────┬───────┘        └──────────────────┘
                                   │
                                   ▼
                    ┌────────────────────────────┐
                    │    PostgreSQL Database     │
                    │    (asyncpg + SQLAlchemy)  │
                    └────────────────────────────┘
```

### Component Responsibilities

#### 1. Customer App (`user_app/`) — Driver Portal
- **User Authentication:** Secure driver registration, sign-in, and JWT session handling using `flutter_secure_storage`.
- **AI Symptom Diagnosis:** Natural language breakdown symptom input, vehicle category detection, severity assessment (LOW / MEDIUM / HIGH / CRITICAL), safety advice, and possible OBD-II Diagnostic Trouble Codes (DTC).
- **GPS-Based Mechanic Discovery:** Captures live driver coordinates via `geolocator` and queries matching mechanics filtered by vehicle type and specialty.
- **Assistance Dispatch:** Submits assistance requests with location, vehicle information, and fault description.
- **Request Tracking:** Visual status tracking showing mechanic progress from request acceptance through job completion.

#### 2. Mechanic App (`mechanic_app/`) — Partner Portal
- **Service Partner Authentication:** Dedicated technician and workshop sign-in and registration flow.
- **Profile & Capabilities Management:** Configures supported vehicle types (Car, Bike, SUV, Van, Truck) and service categories (Engine, Battery, Tyre, Towing, Electrical, Lockout, General Repair).
- **Online / Offline Availability Toggle:** Instant toggle controlling whether the mechanic is currently available to receive dispatched breakdown calls.
- **Incoming Requests Feed:** Real-time stream of incoming roadside assistance requests within the operating radius showing customer details, breakdown location, fault description, and distance.
- **Active Job Progression:** Multi-stage workflow management for accepted jobs: *En Route* $\rightarrow$ *Arrived on Scene* $\rightarrow$ *Work in Progress* $\rightarrow$ *Service Complete*.
- **Performance & Stats:** Summary metrics for completed jobs, customer ratings, and response times.

#### 3. Shared Backend API (`app/`)
- **API & Security Gateway:** FastAPI server with JWT authentication, password hashing (`passlib`/`bcrypt`), role-based access control (`DRIVER` vs. `MECHANIC`), and environment-driven CORS.
- **AI Diagnostic Engine:** Integrates with Google Gemini API for natural-language vehicle problem analysis, with a deterministic local safety fallback engine when offline.
- **Matching & Ranking Algorithm:** Evaluates nearby mechanics using Haversine distance calculations, verified ratings, years of experience, and estimated arrival times (ETA).
- **Request Lifecycle Orchestration:** Enforces atomic state transitions on assistance requests and locks mechanic availability when actively engaged on a job.

#### 4. Prototype Reference (`mobile_app/`)
- Legacy unified single-app prototype retained for reference. Production development takes place exclusively in `user_app/` and `mechanic_app/`.

---

## 2. Assistance Request Lifecycle

Every breakdown request transitions through a strict, deterministic state machine:

```
  [ Driver Dispatches ]
           │
           ▼
     ┌───────────┐
     │  PENDING  │  ◄── Request created; visible to eligible online mechanics
     └─────┬─────┘
           │ Mechanic Accepts
           ▼
     ┌───────────┐
     │ ACCEPTED  │  ◄── Mechanic assigned; mechanic status set to BUSY
     └─────┬─────┘
           │ Technician arrives & begins repair
           ▼
     ┌─────────────┐
     │ IN_PROGRESS │  ◄── On-site diagnostic and roadside assistance underway
     └─────┬───────┘
           │ Assistance complete & verified
           ▼
     ┌───────────┐
     │ COMPLETED │  ◄── Job finalized; mechanic returned to AVAILABLE
     └───────────┘
```

| Status | Triggered By | Backend Action | Visibility |
| :--- | :--- | :--- | :--- |
| **`PENDING`** | Driver creates assistance request | Stored with `status="PENDING"`, unassigned | Visible to driver and available nearby mechanics |
| **`ACCEPTED`** | Mechanic accepts request | Links `mechanic_id`, sets mechanic `is_available=False` | Driver notified; locked to assigning mechanic |
| **`IN_PROGRESS`** | Mechanic starts work | Verifies mechanic ownership, updates status | Driver tracking reflects active on-site service |
| **`COMPLETED`** | Mechanic finishes service | Sets `status="COMPLETED"`, resets mechanic to `is_available=True` | Archived in driver and mechanic history |

---

## 3. Local Development Setup

### 3.1 Prerequisites
- **Python 3.10+** (64-bit)
- **Flutter 3.16+** & **Dart 3.2+**
- **PostgreSQL 14+** (running locally or in Docker)
- Android Studio / Android SDK (with Android Emulator or connected physical device)

---

### 3.2 Backend Setup (`app/`)

1. **Clone the repository and switch to the working branch:**
   ```powershell
   git checkout hardening/two-app-foundation
   ```

2. **Create and activate a virtual environment:**
   ```powershell
   python -m venv venv
   .\venv\Scripts\Activate.ps1
   ```

3. **Install dependencies:**
   ```powershell
   pip install -r requirements.txt
   ```

4. **Configure environment variables:**
   Copy `.env.example` to `.env` and fill in your local settings:
   ```powershell
   Copy-Item .env.example .env
   ```
   *Key variables in `.env`:*
   - `DATABASE_URL`: `postgresql+asyncpg://postgres:postgres@localhost:5432/breakdown_db`
   - `SECRET_KEY`: Random 32+ character string
   - `GEMINI_API_KEY`: Google AI Studio API Key (optional for offline fallback mode)
   - `CORS_ORIGINS`: Allowed origins (e.g., `*` for development)

5. **Initialize database schema and seed sample data:**
   ```powershell
   python reset_db.py
   python seed_dtc.py
   python seed_mechanics_v2.py
   ```

6. **Start the FastAPI development server:**
   ```powershell
   uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
   ```
   - **Health check:** `http://localhost:8000/health`
   - **Interactive Swagger Docs:** `http://localhost:8000/docs`

---

### 3.3 Customer App Setup (`user_app/`)

1. **Navigate to the customer app directory:**
   ```powershell
   cd user_app
   ```

2. **Install Flutter packages:**
   ```powershell
   flutter pub get
   ```

3. **Run the Customer App:**
   - **On Android Emulator:**
     ```powershell
     flutter run
     ```
   - **On a Physical Android Device (connected via USB/LAN):**
     Pass your computer's local Wi-Fi IP address via `--dart-define`:
     ```powershell
     flutter run --dart-define=API_BASE_URL=http://192.168.1.100:8000
     ```

---

### 3.4 Mechanic App Setup (`mechanic_app/`)

1. **Navigate to the mechanic app directory:**
   ```powershell
   cd mechanic_app
   ```

2. **Install Flutter packages:**
   ```powershell
   flutter pub get
   ```

3. **Run the Mechanic App:**
   ```powershell
   flutter run
   ```
   - **Custom backend target:**
     ```powershell
     flutter run --dart-define=API_BASE_URL=http://192.168.1.100:8000
     ```

