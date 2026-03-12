import asyncio
from database.db_connect import AsyncSessionLocal
from database.models import Student, Staff
from sqlalchemy import select

async def main():
    async with AsyncSessionLocal() as session:
        stu = await session.scalar(select(Student).where(Student.id == 1))
        stf = await session.scalar(select(Staff).where(Staff.id == 1))
        print("Student 1:", bool(stu))
        print("Staff 1:", bool(stf))
        
        stf10 = await session.scalar(select(Staff).where(Staff.id > 1))
        print("Some Staff ID:", stf10.id if stf10 else "None")
asyncio.run(main())
