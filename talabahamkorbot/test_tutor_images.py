import asyncio
from database.db_connect import AsyncSessionLocal
from database.models import Staff, UserActivity, Student, TutorGroup, UserActivityImage
from sqlalchemy import select
from sqlalchemy.orm import selectinload, joinedload
import json

async def main():
    async with AsyncSessionLocal() as session:
        # Get an activity that HAS images
        act_stmt = select(UserActivity).options(selectinload(UserActivity.images)).where(UserActivity.images.any())
        res = await session.execute(act_stmt)
        act = res.scalars().first()
        if not act:
            print("No activities with images found in DB.")
            return
            
        print(f"Activity {act.id} has {len(act.images)} images.")
        for img in act.images:
             print("  -", img.file_id)

        # Now test the query from tutor.py (get_group_activities)
        stmt = select(UserActivity).options(
            joinedload(UserActivity.student),
            selectinload(UserActivity.images)
        ).join(Student).where(
            UserActivity.id == act.id
        )
        res = await session.execute(stmt)
        test_act = res.scalars().first()
        if test_act:
             print(f"Via tutor query: Activity {test_act.id} has {len(test_act.images)} images.")
        
asyncio.run(main())
