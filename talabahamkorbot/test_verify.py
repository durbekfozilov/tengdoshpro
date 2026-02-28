import asyncio
from config import HEMIS_ADMIN_TOKEN
from services.hemis_service import HemisService
from database.db_connect import AsyncSessionLocal
from database.models import Staff
from sqlalchemy import select

import logging
logging.basicConfig(level=logging.INFO)

async def test_api():
    async with AsyncSessionLocal() as db:
        result = await db.execute(select(Staff).where(Staff.employee_id_number.is_not(None)))
        st = result.scalars().first()
        if st is None:
            print("No valid staff found in DB.")
            return
            
        emp_id = st.employee_id_number
        print(f"Testing with emp_id: {emp_id}")
        
        # Test the direct verify call
        res = await HemisService.verify_staff_role_from_hemis(emp_id)
        print("verify response:", res)

asyncio.run(test_api())
