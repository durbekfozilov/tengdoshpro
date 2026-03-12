import asyncio
from database.db_connect import AsyncSessionLocal
from database.models import Staff
from sqlalchemy import select
from api.payment import get_click_url
import time

async def main():
    async with AsyncSessionLocal() as session:
        stf = await session.scalar(select(Staff).where(Staff.id > 1))
        if stf:
            print("Found Staff ID:", stf.id)
            res = get_click_url(10000, stf)
            print("URL response:", res)
        else:
            print("No staff")

asyncio.run(main())
