import asyncio
import sys
import os

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sqlalchemy import select
from database.db_connect import AsyncSessionLocal
from database.models import Club, ClubMembership, Student

async def main():
    async with AsyncSessionLocal() as session:
        # Find the demo club
        club = await session.scalar(select(Club).where(Club.name == "Jurnalistika Ijodkorlari"))
        if not club:
            print("Demo club not found.")
            return

        # Let's find some random students
        students = await session.scalars(select(Student).limit(5))
        students = students.all()
        
        if not students:
            print("No students found.")
            return
            
        print(f"Adding {len(students)} mock members to club {club.name}...")
        
        for st in students:
            # Check if exists
            exists = await session.scalar(
                select(ClubMembership)
                .where(ClubMembership.club_id == club.id, ClubMembership.student_id == st.id)
            )
            if not exists:
                mbr = ClubMembership(
                    student_id=st.id,
                    club_id=club.id,
                    status="active"
                )
                session.add(mbr)
                
        await session.commit()
        print("Done seeding members!")

if __name__ == "__main__":
    asyncio.run(main())
