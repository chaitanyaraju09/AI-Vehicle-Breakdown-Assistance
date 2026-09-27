import asyncio
from sqlalchemy.future import select
from app.database import AsyncSessionLocal
from app.models import DTC

SAMPLE_DTCS = [
    {
        "code": "P0300",
        "description": "Random/Multiple Cylinder Misfire Detected",
        "severity": "HIGH",
        "possible_causes": "Fouled spark plugs, faulty ignition coils, low fuel pressure, vacuum leaks.",
        "recommended_action": "Avoid driving at high speed; inspect spark plugs and ignition coils immediately."
    },
    {
        "code": "P0171",
        "description": "System Too Lean (Bank 1)",
        "severity": "MEDIUM",
        "possible_causes": "Dirty MAF sensor, vacuum leaks, weak fuel pump, clogged fuel filter.",
        "recommended_action": "Clean the MAF sensor and check air intake hoses for cracks or leaks."
    },
    {
        "code": "P0420",
        "description": "Catalyst System Efficiency Below Threshold (Bank 1)",
        "severity": "MEDIUM",
        "possible_causes": "Failing catalytic converter, faulty oxygen sensor, exhaust leak.",
        "recommended_action": "Inspect oxygen sensors and exhaust system before replacing the catalytic converter."
    },
    {
        "code": "P0128",
        "description": "Coolant Temperature Below Thermostat Regulating Temperature",
        "severity": "LOW",
        "possible_causes": "Stuck-open thermostat, low coolant level, faulty coolant temperature sensor.",
        "recommended_action": "Check coolant level and replace the thermostat if it remains open."
    },
    {
        "code": "P0455",
        "description": "Evaporative Emission System Leak Detected (Gross Leak)",
        "severity": "LOW",
        "possible_causes": "Loose or damaged gas cap, cracked EVAP hose, faulty purge valve.",
        "recommended_action": "Tighten or replace gas cap; inspect EVAP purge lines if the warning persists."
    }
]

async def seed_data():
    async with AsyncSessionLocal() as session:
        print("Seeding DTC codes into PostgreSQL...")

        for item in SAMPLE_DTCS:
            result = await session.execute(
                select(DTC).where(DTC.code == item["code"])
            )

            existing = result.scalars().first()

            if not existing:
                dtc = DTC(**item)
                session.add(dtc)
                print(f"Added DTC: {item['code']}")
            else:
                print(f"DTC {item['code']} already exists, skipping.")

        await session.commit()
        print("Seeding complete!")

if __name__ == "__main__":
    asyncio.run(seed_data())
