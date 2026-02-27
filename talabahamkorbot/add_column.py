import asyncio
from sqlalchemy import text
from sqlalchemy.ext.asyncio import create_async_engine
from config import DATABASE_URL

async_engine = create_async_engine(DATABASE_URL, echo=False)

async def main():
    async with async_engine.begin() as conn:
        try:
            await conn.execute(text("ALTER TABLE club_events ADD COLUMN is_processed BOOLEAN DEFAULT false;"))
            print("Column added successfully.")
        except Exception as e:
            print(f"Error: {e}")

if __name__ == '__main__':
    asyncio.run(main())
