import asyncio
from sqlalchemy import select
from database.db_connect import engine
from database.models import Staff

async def main():
    async with engine.begin() as conn:
        res = await conn.execute(select(Staff).where(Staff.full_name.ilike('%Nazokat%Saatova%')))
        tutors = res.all()
        for t in tutors:
            print(f"ID: {t.id}, Name: {t.full_name}, Login/Hemis ID: {t.hemis_id}, Role: {t.role}, Password: {t.password}")

if __name__ == "__main__":
    asyncio.run(main())
