import asyncio
from sqlalchemy import select, func
from database.db_connect import AsyncSessionLocal
from database.models import Staff, TutorGroup, Student, User

async def main():
    async with AsyncSessionLocal() as db:
        group = "02-24"
        stmt = (
            select(Student, User.id.is_not(None).label('is_registered'))
            .outerjoin(User, User.hemis_login == Student.hemis_login)
            .where(Student.group_number.ilike(f"{group}%"))
            .limit(10)
        )
        res = await db.execute(stmt)
        for row in res.all():
            s, is_reg = row
            print(f"{s.full_name} | Reg: {is_reg}")

if __name__ == "__main__":
    import sys
    sys.path.append("/home/user/talabahamkor/talabahamkorbot")
    asyncio.run(main())
