import asyncio
import io
import aiohttp
from bot import bot
from config import BOT_TOKEN

async def test():
    file_id = "BQACAgIAAxkBAAI-KGe...?" # Need to fetch actual DB file
    
    # Or just fetch any file id from DB!
    from database.session import async_session
    from sqlalchemy import text
    
    async with async_session() as session:
        res = await session.execute(text("SELECT telegram_file_id FROM documents WHERE id = 14"))
        file_id = res.scalar()
        if not file_id:
            print("File 14 not found!")
            return
            
        print("File ID:", file_id)
        tg_file = await bot.get_file(file_id)
        
        # Method 1
        file_io = io.BytesIO()
        await bot.download_file(tg_file.file_path, file_io)
        b1 = file_io.getvalue()
        
        # Method 2
        download_url = f"https://api.telegram.org/file/bot{BOT_TOKEN}/{tg_file.file_path}"
        async with aiohttp.ClientSession() as http_session:
            async with http_session.get(download_url) as resp:
                b2 = await resp.read()
        
        print(f"bot.download_file len: {len(b1)}")
        print(f"aiohttp len: {len(b2)}")
        print(f"Are they identical? {b1 == b2}")
        
        if len(b1) > 0:
            print(f"b1 signature: {b1[:10]}")
            
asyncio.run(test())
