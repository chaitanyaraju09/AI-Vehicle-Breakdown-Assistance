import asyncio
from app.database import AsyncSessionLocal
from app.models import Mechanic
from sqlalchemy.future import select

SAMPLE_MECHANICS = [
    {
        "name": "Rajesh Auto Works",
        "phone_number": "9849012345",
        "service_type": "General Repairs",
        "latitude": 17.3890,
        "longitude": 78.4890,
        "is_available": True,
        "rating": 4.8,
        "experience_years": 8
    },
    {
        "name": "Hyderabad Express Towing",
        "phone_number": "9849098765",
        "service_type": "Towing Service",
        "latitude": 17.3950,
        "longitude": 78.4920,
        "is_available": True,
        "rating": 4.6,
        "experience_years": 5
    },
    {
        "name": "QuickFix Battery & Electrical",
        "phone_number": "9849055555",
        "service_type": "Electrical & Battery",
        "latitude": 17.3810,
        "longitude": 78.4810,
        "is_available": True,
        "rating": 4.9,
        "experience_years": 10
    }
]

async def seed_mechanics():
    async with AsyncSessionLocal() as db:
        print("Seeding Mechanics into PostgreSQL...")

        for mech_data in SAMPLE_MECHANICS:
            result = await db.execute(
                select(Mechanic).where(
                    Mechanic.name == mech_data["name"]
                )
            )

            if not result.scalars().first():
                mech = Mechanic(**mech_data)
                db.add(mech)
                print(f"Added Mechanic: {mech_data['name']}")
            else:
                print(
                    f"Mechanic {mech_data['name']} already exists, skipping."
                )

        await db.commit()
        print("Seeding complete!")

if __name__ == "__main__":
    asyncio.run(seed_mechanics())
