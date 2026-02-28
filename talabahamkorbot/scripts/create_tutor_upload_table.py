import asyncio
from database.db_connect import engine
from database.models import Base, TutorPendingUpload

async def init_db():
    async with engine.begin() as conn:
        # Create only the new table if it doesn't exist
        await conn.run_sync(Base.metadata.create_all)
    print("TutorPendingUpload table created successfully!")

if __name__ == "__main__":
    asyncio.run(init_db())
