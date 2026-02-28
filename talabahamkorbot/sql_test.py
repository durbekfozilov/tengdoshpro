import asyncio
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy import select

async def main():
    try:
        from config import DATABASE_URL
        from database.models import Staff
        engine = create_async_engine(DATABASE_URL)
        async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
        
        async with async_session() as session:
            stmt = select(Staff).limit(5)
            res2 = await session.execute(stmt)
            for s in res2.scalars().all():
                print("Staff:", s.full_name, "Uni:", s.university_id, "Role:", s.role, "Dept:", s.department)
    except Exception as e:
        print("Error:", e)

if __name__ == "__main__":
    import asyncio
    asyncio.run(main())
