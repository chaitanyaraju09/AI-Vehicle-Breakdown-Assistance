import asyncio
from sqlalchemy import text
from app.database import engine

async def check_schema():
    async with engine.connect() as conn:
        result = await conn.execute(text("""
            SELECT column_name
            FROM information_schema.columns
            WHERE table_name = 'mechanics'
            ORDER BY ordinal_position
        """))

        print("Mechanics table columns:")
        for row in result:
            print("-", row[0])

if __name__ == "__main__":
    asyncio.run(check_schema())
