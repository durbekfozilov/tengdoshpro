import asyncio
from sqlalchemy import text
from database.db_connect import AsyncSessionLocal

async def migrate():
    async with AsyncSessionLocal() as session:
        # 1. Add column
        await session.execute(text("ALTER TABLE rating_records ADD COLUMN IF NOT EXISTS activation_id INTEGER REFERENCES rating_activations(id) ON DELETE SET NULL"))
        # 2. Add index
        await session.execute(text("CREATE INDEX IF NOT EXISTS ix_rating_records_activation_id ON rating_records (activation_id)"))
        await session.commit()
    print("Migration successful: added activation_id to rating_records")

if __name__ == "__main__":
    asyncio.run(migrate())
