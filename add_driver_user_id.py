import asyncio

from sqlalchemy import text
from app.database import engine


async def main():
    async with engine.begin() as conn:
        await conn.execute(
            text(
                """
                ALTER TABLE assistance_requests
                ADD COLUMN IF NOT EXISTS driver_user_id INTEGER
                REFERENCES users(id)
                """
            )
        )

    print("driver_user_id column added successfully")


asyncio.run(main())