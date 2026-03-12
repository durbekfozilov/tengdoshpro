import asyncio
from bot import bot
from database.db_connect import AsyncSessionLocal
from sqlalchemy import text
import pprint

async def run():
    async with AsyncSessionLocal() as session:
        # get docs matching student name Mardonova Malika
        res = await session.execute(text("SELECT d.id, d.file_name, d.mime_type, d.file_type, d.telegram_file_id FROM student_documents d JOIN students s ON d.student_id = s.id WHERE s.full_name LIKE '%Mardonova%Malika%' LIMIT 5"))
        docs = res.fetchall()
        for doc in docs:
            print("DB ROW:", dict(doc._mapping))
            try:
                tg_file = await bot.get_file(doc.telegram_file_id)
                print("TG FILE PATH:", tg_file.file_path)
            except Exception as e:
                print("Error getting tg file:", e)
            print("-" * 50)
            
asyncio.run(run())
