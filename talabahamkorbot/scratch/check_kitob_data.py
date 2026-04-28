import asyncio
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy import select
import sys
import os

sys.path.append('/home/user/talabahamkor/talabahamkorbot')
from database.models import RatingRecord, RatingActivation

DATABASE_URL = "sqlite+aiosqlite:///database/app.db"
engine = create_async_engine(DATABASE_URL)
AsyncSessionLocal = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

async def check_data():
    async with AsyncSessionLocal() as db:
        stmt = select(RatingRecord).where(RatingRecord.role_type == 'kitobxonlik')
        res = await db.execute(stmt)
        records = res.scalars().all()
        print(f"Found {len(records)} kitobxonlik records")
        for r in records:
            print(f"ID: {r.id}, StudentID: {r.user_id}, Rating: {r.rating}")
            
        stmt2 = select(RatingActivation).where(RatingActivation.role_type == 'kitobxonlik')
        res2 = await db.execute(stmt2)
        acts = res2.scalars().all()
        print(f"Found {len(acts)} kitobxonlik activations")

if __name__ == "__main__":
    asyncio.run(check_data())
