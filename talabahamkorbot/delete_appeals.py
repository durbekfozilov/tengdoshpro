import asyncio
from database.db_connect import AsyncSessionLocal
from sqlalchemy import text

async def run():
    async with AsyncSessionLocal() as session:
        # Check current appeals
        res = await session.execute(text("SELECT id FROM user_appeals"))
        print(f"Total appeals found: {len(res.fetchall())}")
        
        # Check current feedback
        res2 = await session.execute(text("SELECT id FROM student_feedback"))
        print(f"Total feedbacks found: {len(res2.fetchall())}")
            
        print("Trashing them...")
        await session.execute(text("DELETE FROM feedback_replies"))
        await session.execute(text("DELETE FROM user_appeals"))
        await session.execute(text("DELETE FROM student_feedback"))
        await session.commit()
        print("Done.")

asyncio.run(run())
