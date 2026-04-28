import asyncio
from database.db_connect import AsyncSessionLocal
from database.models import Student
from sqlalchemy import select

async def check():
    session = AsyncSessionLocal()
    s = await session.execute(select(Student).where(Student.id == 756))
    student = s.scalar_one_or_none()
    if student:
        print(f"Student: {student.full_name}, GPA: {student.gpa}, Group: {student.group_number}")
    else:
        print("Not found")
    await session.close()

if __name__ == "__main__":
    asyncio.run(check())
