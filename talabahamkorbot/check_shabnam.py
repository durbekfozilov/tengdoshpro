import asyncio
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy import text
from config import DATABASE_URL

async_engine = create_async_engine(DATABASE_URL, echo=False)
async_session = sessionmaker(async_engine, expire_on_commit=False, class_=AsyncSession)

async def main():
    async with async_session() as session:
        # Check if Shabnam is premium
        res = await session.execute(text("""
            SELECT full_name, is_premium, premium_expiry, hemis_role FROM students WHERE full_name LIKE '%Shabnam%'
        """))
        for row in res.fetchall():
            print(dict(row._mapping))

if __name__ == '__main__':
    asyncio.run(main())
