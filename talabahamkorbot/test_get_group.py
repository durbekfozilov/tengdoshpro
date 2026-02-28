import asyncio
from database.db_connect import engine
from database.models import Student, TutorGroup, Staff
from sqlalchemy import select

async def main():
    async with engine.begin() as conn:
        res = await conn.execute(select(Staff).where(Staff.role == 'tutor').limit(1))
        tutor = res.first()
        if not tutor:
            print("No tutors")
            return
        
        res = await conn.execute(select(TutorGroup).where(TutorGroup.tutor_id == tutor.id))
        groups = res.all()
        for g in groups:
            print(f"Group: {g.group_number}")
            res2 = await conn.execute(select(Student).where(Student.group_number == g.group_number))
            students = res2.all()
            print(f"Students in {g.group_number}: {len(students)}")
            if len(students) > 0:
                print(f"  First student: {students[0].full_name} | {students[0].group_number}")

if __name__ == "__main__":
    asyncio.run(main())
