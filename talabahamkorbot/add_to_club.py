import asyncio
from config import DATABASE_URL
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from database.models import Student, Club, ClubMembership
from sqlalchemy import select

async_engine = create_async_engine(DATABASE_URL, echo=False)
async_session = sessionmaker(async_engine, expire_on_commit=False, class_=AsyncSession)

async def main():
    async with async_session() as session:
        student = await session.scalar(select(Student).where(Student.hemis_login == "395251101410"))
        if not student:
            print("Talaba topilmadi!")
            return
        
        clubs = await session.scalars(select(Club))
        clubs_list = clubs.all()
        print("Mavjud klublar:")
        
        club_to_join = None
        for c in clubs_list:
            print(f"- {c.name} (ID: {c.id})")
            if 'demo' in c.name.lower():
                club_to_join = c
                
        if not club_to_join and len(clubs_list) > 0:
            print("\nDemo klub topilmadi, iltimos nomini tekshiring...")
            club_to_join = clubs_list[0]
            print(f"Boshqa klub ustida urinib kuramiz: {club_to_join.name}")

        if not club_to_join:
            print("Hech qanday klub topilmadi!")
            return
            
        print(f"\nQuyidagi klubga qo'shilmoqda: {club_to_join.name}")
        
        existing = await session.scalar(select(ClubMembership).where(
            ClubMembership.student_id == student.id,
            ClubMembership.club_id == club_to_join.id
        ))
        
        if existing:
            print("Ushbu talaba allaqachon klub a'zosi!")
            return
            
        membership = ClubMembership(
            club_id=club_to_join.id,
            student_id=student.id,
            status="active"
        )
        session.add(membership)
        await session.commit()
        print("Muvaffaqiyatli klubga qo'shildi!")

if __name__ == '__main__':
    asyncio.run(main())
