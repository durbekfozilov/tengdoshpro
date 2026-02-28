import asyncio
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy import text
from config import DATABASE_URL

async_engine = create_async_engine(DATABASE_URL, echo=False)
async_session = sessionmaker(async_engine, expire_on_commit=False, class_=AsyncSession)

async def main():
    async with async_session() as session:
        # Get users and their activities
        res = await session.execute(text("""
            SELECT s.full_name, a.id, a.category, a.name, a.status 
            FROM user_activities a
            JOIN students s ON a.student_id = s.id
            ORDER BY a.id DESC LIMIT 10
        """))
        print("Last 10 User Activities:")
        for row in res.fetchall():
            print(dict(row._mapping))

if __name__ == '__main__':
    asyncio.run(main())
