import asyncio
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy import select
from database.models import Student, StudentFeedback, Staff, StaffRole
from config import DATABASE_URL

async def main():
    engine = create_async_engine(DATABASE_URL)
    async_session = sessionmaker(engine, expire_on_commit=False, class_=AsyncSession)
    
    async with async_session() as session:
        # Check the recent appeals
        print("--- RECENT APPEALS ---")
        stmt = select(StudentFeedback).order_by(StudentFeedback.created_at.desc()).limit(5)
        res = await session.execute(stmt)
        appeals = res.scalars().all()
        for a in appeals:
            print(f"ID={a.id}, Text={a.text[:30]}, Role={a.assigned_role}, Status={a.status}, Student={a.student_full_name}")
            
        # Check Staff "Sanjar"
        print("\n--- STAFF SANJAR ---")
        stmt_staff = select(Staff).where(Staff.login == "ad1870724$")
        res_staff = await session.execute(stmt_staff)
        staff = res_staff.scalar_one_or_none()
        if staff:
            print(f"ID={staff.id}, Name={staff.full_name}, Role={staff.role}, Uni={staff.university_id}, Fac={staff.faculty_id}")
        else:
            print("Staff not found with login ad1870724$")

if __name__ == "__main__":
    asyncio.run(main())
