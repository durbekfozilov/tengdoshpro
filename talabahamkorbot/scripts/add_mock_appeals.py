import asyncio
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy import select
from database.models import Student, StudentFeedback
from config import DATABASE_URL

async def main():
    engine = create_async_engine(DATABASE_URL)
    async_session = sessionmaker(engine, expire_on_commit=False, class_=AsyncSession)
    
    async with async_session() as session:
        # Get a student
        st = await session.execute(select(Student).limit(1))
        student = st.scalar_one_or_none()
        
        if not student:
            print("No students found in DB. Need a student first.")
            return

        print(f"Creating 10 demo appeals for rahbariyat using student_id={student.id}")
        
        feedbacks = [
            StudentFeedback(
                student_id=student.id,
                text="Yotoqxonada issiq suv muammosi bo'yicha rahbariyatdan yordam so'raymiz.",
                status="pending",
                assigned_role="rahbariyat",
                is_anonymous=False,
                student_full_name=student.full_name,
                student_group=student.group_number,
                student_faculty=student.faculty_name,
                student_phone=student.phone,
                ai_topic="Yotoqxona",
                ai_sentiment="negative"
            ),
            StudentFeedback(
                student_id=student.id,
                text="Universitet kutubxonasini kechgacha ochiq qoldirish bo'yicha taklifim bor edi.",
                status="pending",
                assigned_role="rahbariyat",
                is_anonymous=False,
                student_full_name=student.full_name,
                student_group=student.group_number,
                student_faculty=student.faculty_name,
                student_phone=student.phone,
                ai_topic="Infratuzilma",
                ai_sentiment="neutral"
            ),
            StudentFeedback(
                student_id=student.id,
                text="Stipendiya to'lovlari bu safar nima uchun kechikyapti?",
                status="pending",
                assigned_role="rahbariyat",
                is_anonymous=True,
                student_full_name="Anonim Talaba",
                student_group=student.group_number,
                student_faculty=student.faculty_name,
                student_phone=None,
                ai_topic="Moliya",
                ai_sentiment="neutral"
            ),
            StudentFeedback(
                student_id=student.id,
                text="Dars jadvallarida ustma-ust tushish holatlari ko'p, buni to'g'irlab bo'ladimi?",
                status="pending",
                assigned_role="rahbariyat",
                is_anonymous=False,
                student_full_name=student.full_name,
                student_group=student.group_number,
                student_faculty=student.faculty_name,
                student_phone=student.phone,
                ai_topic="O'quv jarayoni",
                ai_sentiment="negative"
            ),
            StudentFeedback(
                student_id=student.id,
                text="Talabalar uchun yengillashtirilgan transport tizimi yoki avtobus yo'lga qo'yishini suraymiz",
                status="pending",
                assigned_role="rahbariyat",
                is_anonymous=False,
                student_full_name=student.full_name,
                student_group=student.group_number,
                student_faculty=student.faculty_name,
                student_phone=student.phone,
                ai_topic="Infratuzilma",
                ai_sentiment="neutral"
            ),
            StudentFeedback(
                student_id=student.id,
                text="O'qish jarayoni va o'qituvchilarning bilim berish sifatidan judayam mamnunman! Rahmat",
                status="resolved",
                assigned_role="rahbariyat",
                is_anonymous=False,
                student_full_name=student.full_name,
                student_group=student.group_number,
                student_faculty=student.faculty_name,
                student_phone=student.phone,
                ai_topic="O'quv jarayoni",
                ai_sentiment="positive"
            ),
            StudentFeedback(
                student_id=student.id,
                text="Qishki ta'til vaqti qachondan boshlanishi aniq emas, iltimos shu bo'yicha rasmiy ma'lumot bersangiz.",
                status="processing",
                assigned_role="rahbariyat",
                is_anonymous=False,
                student_full_name=student.full_name,
                student_group=student.group_number,
                student_faculty=student.faculty_name,
                student_phone=student.phone,
                ai_topic="Boshqa",
                ai_sentiment="neutral"
            ),
            StudentFeedback(
                student_id=student.id,
                text="Talabalar festivalini juda zo'r tashkillashtirishibdi. Qo'shimcha loyihalarni ham qachon ko'ramiz?",
                status="replied",
                assigned_role="rahbariyat",
                is_anonymous=False,
                student_full_name=student.full_name,
                student_group=student.group_number,
                student_faculty=student.faculty_name,
                student_phone=student.phone,
                ai_topic="Tadbirlar",
                ai_sentiment="positive"
            ),
            StudentFeedback(
                student_id=student.id,
                text="Kontrakt to'lash muddati bo'yicha imtiyoz olsa bo'ladimi? Oilaviy sharoitim og'ir.",
                status="pending",
                assigned_role="rahbariyat",
                is_anonymous=False,
                student_full_name=student.full_name,
                student_group=student.group_number,
                student_faculty=student.faculty_name,
                student_phone=student.phone,
                ai_topic="Moliya",
                ai_sentiment="negative"
            ),
            StudentFeedback(
                student_id=student.id,
                text="Men xalqaro olimpiadada qatnashish uchun nima qilishim kerak? Rahbariyat bizni qollab-quvvatlaydimi?",
                status="pending",
                assigned_role="rahbariyat",
                is_anonymous=False,
                student_full_name=student.full_name,
                student_group=student.group_number,
                student_faculty=student.faculty_name,
                student_phone=student.phone,
                ai_topic="O'quv jarayoni",
                ai_sentiment="neutral"
            ),
        ]
        
        session.add_all(feedbacks)
        await session.commit()
        print("Successfully created 10 rahbariyat appeals.")

if __name__ == "__main__":
    asyncio.run(main())
