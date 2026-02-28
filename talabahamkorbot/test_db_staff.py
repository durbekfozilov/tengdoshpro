import asyncio
from sqlalchemy import select
from database.db_connect import AsyncSessionLocal
from database.models import Staff

async def main():
    async with AsyncSessionLocal() as session:
        result = await session.execute(select(Staff).where(Staff.full_name.ilike('%Farmonov%')))
        staff = result.scalars().all()
        for s in staff:
            print(f"ID: {s.id}, Name: {s.full_name}, Hemis ID: {s.hemis_id}, Telegram: {s.telegram_id}, Role: {s.role}")
            
        result = await session.execute(select(Staff).where(Staff.hemis_id == 395191100477))
        staff2 = result.scalars().all()
        for s in staff2:
            print(f"By HemisID - ID: {s.id}, Name: {s.full_name}, Role: {s.role}")
            

if __name__ == "__main__":
    asyncio.run(main())
