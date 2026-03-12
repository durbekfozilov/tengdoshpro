import asyncio
import io
import aiohttp
import importlib
from sqlalchemy import text
from bot import bot
from config import BOT_TOKEN
from database.db_connect import AsyncSessionLocal

async def test():
    async with AsyncSessionLocal() as session:
        res = await session.execute(text("SELECT telegram_file_id FROM student_documents WHERE id = 14 LIMIT 1"))
        file_id = res.scalar()
        if not file_id:
            print("No file 14")
            return
            
    tg_file = await bot.get_file(file_id)
    file_io = io.BytesIO()
    await bot.download_file(tg_file.file_path, file_io)
    b1 = file_io.getvalue()
    
    download_url = f"https://api.telegram.org/file/bot{BOT_TOKEN}/{tg_file.file_path}"
    async with aiohttp.ClientSession() as http_sess:
        async with http_sess.get(download_url) as resp:
            b2 = await resp.read()
            
    print("bot len:", len(b1))
    print("aiohttp len:", len(b2))
    print("Bytes equal?", b1 == b2)
    
    with open("file1.pdf", "wb") as f:
        f.write(b1)

asyncio.run(test())
