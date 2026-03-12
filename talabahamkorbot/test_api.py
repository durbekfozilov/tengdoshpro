import asyncio
from database.db_connect import AsyncSessionLocal
from database.models import Student
from sqlalchemy import select
from api.student import get_my_profile

async def main():
    async with AsyncSessionLocal() as session:
        result = await session.execute(select(Student).where(Student.hemis_login == "395251101397"))
        student = result.scalar_one_or_none()
        if student:
            # We don't have the depends DB injected but we can fake it since get_my_profile doesn't use DB directly inside unless it touches lazy loaded fields... Wait it uses db parameter: 
            # `async def get_my_profile(student: Student = Depends(...), db: AsyncSession = Depends(get_db)):`
            data = await get_my_profile(student=student, db=session)
            print(f"API Returned: is_premium={data.get('is_premium')}")

asyncio.run(main())
