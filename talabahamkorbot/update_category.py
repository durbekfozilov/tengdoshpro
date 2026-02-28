import asyncio
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy import text
from config import DATABASE_URL

async_engine = create_async_engine(DATABASE_URL, echo=False)
async_session = sessionmaker(async_engine, expire_on_commit=False, class_=AsyncSession)

async def main():
    async with async_session() as session:
        # Update Tadbir to togarak
        await session.execute(text("UPDATE user_activities SET category = 'togarak' WHERE category = 'Tadbir'"))
        await session.commit()
        print("Updated activities.")

if __name__ == '__main__':
    asyncio.run(main())
