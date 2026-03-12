import asyncio
from database.db_connect import async_session
from database.models import Staff
from sqlalchemy import select
from api.payment import get_click_url

async def main():
    async with async_session() as session:
        staff = await session.scalar(select(Staff))
        if staff:
            print("Staff ID:", staff.id)
            res = get_click_url(10000, staff)
            print("Result:", res)
        else:
            print("No staff found")

asyncio.run(main())
