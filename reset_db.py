import asyncio
from app.database import engine, Base
from app.models import User, DTC, AssistanceRequest, Mechanic


async def reset_database():
    print("Resetting PostgreSQL tables to match new schema...")

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
        await conn.run_sync(Base.metadata.create_all)

    print("Database schema successfully recreated!")


if __name__ == "__main__":
    asyncio.run(reset_database())