import sys
import asyncio
from sqlalchemy import select
from database.db_connect import AsyncSessionLocal
from database.models import Staff

async def main():
    async with AsyncSessionLocal() as db:
        result = await db.execute(select(Staff).where(Staff.jshshir == '30302995690037'))
        st = result.scalars().all()
        for s in st:
            print(f"ID={s.id} Name={s.full_name} EmpID={s.employee_id_number} JSHSHIR={s.jshshir} Role={s.role}")
        print("Done")

asyncio.run(main())
