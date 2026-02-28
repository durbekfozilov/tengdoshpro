import asyncio
from sqlalchemy import select
from database.db_connect import AsyncSessionLocal
from database.models import Staff

async def main():
    async with AsyncSessionLocal() as db:
        result = await db.execute(select(Staff))
        st = result.scalars().all()
        with open("staff_dump.txt", "w") as f:
            for s in st:
                f.write(f"ID={s.id} Name={s.full_name} EmpID={s.employee_id_number} JSHSHIR={s.jshshir} Role={s.role}\n")
        print("Done")

asyncio.run(main())
