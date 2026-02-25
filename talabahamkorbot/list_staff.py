import asyncio
import sys
import os
sys.path.append(os.getcwd())

from database.db_connect import AsyncSessionLocal
from database.models import Staff
from sqlalchemy.future import select

async def main():
    async with AsyncSessionLocal() as session:
        result = await session.execute(select(Staff))
        staff_members = result.scalars().all()
        print(f"Barcha xodimlar soni: {len(staff_members)}\n")
        print(f"{'ID':<4} | {'F.I.SH.':<30} | {'Rol':<20} | {'Xodim ID (EmpID)':<15} | {'HEMIS ID':<10}")
        print("-" * 90)
        for s in staff_members:
            role = str(s.role.value) if hasattr(s.role, 'value') else str(s.role)
            print(f"{s.id:<4} | {str(s.full_name)[:30]:<30} | {role:<20} | {str(s.employee_id_number):<15} | {str(s.hemis_id):<10}")

asyncio.run(main())
