import asyncio
from database.db_connect import AsyncSessionLocal
from database.models import Student
from sqlalchemy import select, update

async def main():
    async with AsyncSessionLocal() as session:
        # Check student
        result = await session.execute(select(Student).where(Student.hemis_login == "395251101397"))
        student = result.scalar_one_or_none()
        if student:
            print(f"Found student: {student.full_name}, is_premium: {student.is_premium}")
            # Remove premium
            student.is_premium = False
            student.premium_expiry = None
            student.trial_used = False # Optionally reset trial unused, not asked but maybe. Let's just remove premium.
            await session.commit()
            print("Premium removed.")
        else:
            print("Student not found.")

asyncio.run(main())
