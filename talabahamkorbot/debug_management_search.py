import asyncio
from database.db_connect import AsyncSessionLocal
from api.management import search_mgmt_students
from database.models import Staff
from sqlalchemy import select

async def main():
    async with AsyncSessionLocal() as db:
        staff = await db.scalar(select(Staff).where(Staff.role == 'developer').limit(1))
        if not staff:
            print("No developer staff found.")
            return

        print("Testing search_mgmt_students as:", staff.full_name)
        try:
            res = await search_mgmt_students(query="ali", staff=staff, db=db)
            print("SUCCESS:", res)
        except Exception as e:
            import traceback
            traceback.print_exc()

if __name__ == '__main__':
    asyncio.run(main())
