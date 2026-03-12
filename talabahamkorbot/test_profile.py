import asyncio
from database.db_connect import AsyncSessionLocal
from database.models import Student
from sqlalchemy import select

async def main():
    async with AsyncSessionLocal() as session:
        result = await session.execute(select(Student).where(Student.hemis_login == "395251101397"))
        student = result.scalar_one_or_none()
        if student:
            print(f"Student: is_premium={student.is_premium}, premium_expiry={student.premium_expiry}")

asyncio.run(main())
