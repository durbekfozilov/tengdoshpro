import asyncio
from database.db_connect import AsyncSessionLocal
from database.models import UserActivityImage, UserActivity
from sqlalchemy import select

async def check():
    session = AsyncSessionLocal()
    q = select(UserActivityImage.file_id).join(UserActivity).where(UserActivity.student_id == 756).limit(1)
    res = await session.execute(q)
    fid = res.scalar()
    print(fid)
    await session.close()

if __name__ == "__main__":
    asyncio.run(check())
