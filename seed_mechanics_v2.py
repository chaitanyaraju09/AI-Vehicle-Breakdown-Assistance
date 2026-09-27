import asyncio
from app.database import AsyncSessionLocal
from app.models import Mechanic
from sqlalchemy.future import select

SAMPLE_PROVIDERS = [
    {
        "name": "Apex Mobile Auto Care",
        "phone_number": "9800011111",
        "service_categories": "Battery,Tyre,Engine,Electrical,General Repair",
        "supported_vehicle_types": "Car,SUV,Van,Pickup",
        "latitude": 17.3890,
        "longitude": 78.4890,
        "is_available": True,
        "rating": 4.9,
        "experience_years": 9
    },
    {
        "name": "Rapid Towing & Recovery",
        "phone_number": "9800022222",
        "service_categories": "Towing,Accident Recovery",
        "supported_vehicle_types": "Car,SUV,Van,Pickup,Commercial Vehicle,Truck",
        "latitude": 17.3950,
        "longitude": 78.4920,
        "is_available": True,
        "rating": 4.7,
        "experience_years": 6
    },
    {
        "name": "VoltShift EV Support & Battery",
        "phone_number": "9800033333",
        "service_categories": "Battery,Electrical,AC,EV Assistance",
        "supported_vehicle_types": "Car,SUV,Electric Vehicle (EV),Scooter",
        "latitude": 17.3810,
        "longitude": 78.4810,
        "is_available": True,
        "rating": 4.8,
        "experience_years": 5
    },
    {
        "name": "MotoRescue 2-Wheeler Specialist",
        "phone_number": "9800044444",
        "service_categories": "Battery,Tyre,Engine,General Repair,Fuel",
        "supported_vehicle_types": "Bike,Scooter",
        "latitude": 17.3860,
        "longitude": 78.4840,
        "is_available": True,
        "rating": 4.6,
        "experience_years": 7
    },
    {
        "name": "KeyStop Lockout & Fuel Delivery",
        "phone_number": "9800055555",
        "service_categories": "Lockout,Fuel,Battery",
        "supported_vehicle_types": "Car,SUV,Van,Pickup,Truck,Bus",
        "latitude": 17.3830,
        "longitude": 78.4870,
        "is_available": True,
        "rating": 4.9,
        "experience_years": 11
    }
]

async def seed_providers():
    async with AsyncSessionLocal() as db:
        print("Seeding multi-category service providers...")

        for provider_data in SAMPLE_PROVIDERS:
            result = await db.execute(
                select(Mechanic).where(
                    Mechanic.name == provider_data["name"]
                )
            )

            if not result.scalars().first():
                provider = Mechanic(**provider_data)
                db.add(provider)
                print(f"Added Provider: {provider_data['name']}")
            else:
                print(
                    f"Provider {provider_data['name']} already exists, skipping."
                )

        await db.commit()
        print("Seeding complete!")

if __name__ == "__main__":
    asyncio.run(seed_providers())
