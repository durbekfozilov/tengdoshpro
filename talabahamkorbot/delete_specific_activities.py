import asyncio
from sqlalchemy.orm import selectinload
from sqlalchemy import select

from database.db_connect import AsyncSessionLocal
from database.models import Student, UserActivity, UserActivityImage

async def delete_demo_activities():
    names = [
        "Nasriddinova Navbahor Toxir Qizi",
        "Jamolova Shabnam Shaxriyorovna"
    ]
    
    async with AsyncSessionLocal() as session:
        for name in names:
            # Using ilike or just equals
            res = await session.execute(
                select(Student).where(Student.full_name.ilike(f"%{name}%"))
            )
            students = res.scalars().all()
            for student in students:
                print(f"Found student: {student.full_name} (ID: {student.id}, Hemis: {student.hemis_login})")
                
                # Get their activities
                act_res = await session.execute(
                    select(UserActivity).where(UserActivity.student_id == student.id)
                )
                activities = act_res.scalars().all()
                if activities:
                    for act in activities:
                        print(f"  Deleting activity: {act.name} (ID: {act.id})")
                        await session.delete(act)
                    await session.commit()
                    print(f"  Deleted {len(activities)} activities for {name}.")
                else:
                    print(f"  No activities found for {name}.")

if __name__ == "__main__":
    asyncio.run(delete_demo_activities())
