import asyncio
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy import select
import sys
import os

# Add parent directory to sys.path to import models
sys.path.append('/home/user/talabahamkor/talabahamkorbot')

from database.models import RatingActivation, RatingRecord, Student

# Correct DATABASE_URL for Postgres in this environment
DATABASE_URL = "postgresql+asyncpg://postgres:Mukhammadali2623@127.0.0.1:5432/talabahamkorbot_db"
engine = create_async_engine(DATABASE_URL, echo=True)
AsyncSessionLocal = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

QUESTIONS = [
    {"id": 1, "question": "Dunyodagi eng katta kutubxona qayerda joylashgan?", "options": ["London", "Vashington", "Parij", "Toshkent"], "answer": "Vashington"},
    {"id": 2, "question": "'O'tkan kunlar' asarining muallifi kim?", "options": ["Oybek", "Abdulla Qodiriy", "G'afur G'ulom", "Cho'lpon"], "answer": "Abdulla Qodiriy"},
    {"id": 3, "question": "Kitob bayrami O'zbekistonda qachon nishonlanadi?", "options": ["Aprel", "May", "Sentyabr", "Dekabr"], "answer": "May"},
    {"id": 4, "question": "Eng ko'p tillarga tarjima qilingan o'zbek asari?", "options": ["O'tkan kunlar", "Yulduzli tunlar", "Mehrobdan chayon", "Shum bola"], "answer": "O'tkan kunlar"},
    {"id": 5, "question": "Birinchi bosilgan o'zbek kitobi qachon nashr etilgan?", "options": ["1871", "1917", "1991", "1850"], "answer": "1871"},
]

ANSWERS = [
    {"question_id": 1, "selected_option": "Vashington", "is_correct": True},
    {"question_id": 2, "selected_option": "Abdulla Qodiriy", "is_correct": True},
    {"question_id": 3, "selected_option": "Aprel", "is_correct": False},
    {"question_id": 4, "selected_option": "O'tkan kunlar", "is_correct": True},
    {"question_id": 5, "selected_option": "1871", "is_correct": True},
]

async def create_mock_data():
    async with AsyncSessionLocal() as db:
        # 1. Create Activation
        activation = RatingActivation(
            university_id=1,
            role_type='kitobxonlik',
            title='Kitobxonlik Madaniyati Testi',
            description='2024-yilgi kitobxonlik tanlovi uchun maxsus test.',
            is_active=True,
            questions=QUESTIONS
        )
        db.add(activation)
        await db.commit()
        await db.refresh(activation)
        
        # 2. Find Student #756
        stmt = select(Student).where(Student.id == 756)
        res = await db.execute(stmt)
        student = res.scalar_one_or_none()
        
        if not student:
            print("Student #756 not found!")
            return

        # 3. Create Record
        # Setting rated_person_id to 64 (tutor) as it is NOT NULL in DB
        record = RatingRecord(
            user_id=student.id,
            rated_person_id=64,
            university_id=student.university_id or 1,
            activation_id=activation.id,
            role_type='kitobxonlik',
            rating=16, # The score out of 20
            answers=ANSWERS
        )
        db.add(record)
        await db.commit()
        print(f"Mock kitobxonlik test created for {student.full_name} (#756) in Postgres")

if __name__ == "__main__":
    asyncio.run(create_mock_data())
