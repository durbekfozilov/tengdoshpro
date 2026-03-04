from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse, Response
from bot import bot
import aiohttp

router = APIRouter()

async def stream_telegram_file(url: str):
    async with aiohttp.ClientSession() as session:
        async with session.get(url) as resp:
            if resp.status != 200:
                return
            async for chunk in resp.content.iter_chunked(4096):
                yield chunk


@router.get("/{file_id}")
async def get_telegram_file(file_id: str):
    try:
        file = await bot.get_file(file_id)
        if not file.file_path:
            raise HTTPException(status_code=404, detail="File path not found")

        token = bot.token
        file_url = f"https://api.telegram.org/file/bot{token}/{file.file_path}"
        
        async with aiohttp.ClientSession() as session:
            async with session.get(file_url) as resp:
                if resp.status != 200:
                    raise HTTPException(status_code=404, detail="File not found on Telegram")
                body = await resp.read()
                return Response(content=body, media_type="image/jpeg")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Proxy Error: {str(e)}")

# Fallback alias for Flutter bug where /api/v1 is appended twice
@router.get("/api/v1/files/{file_id}")
async def get_telegram_file_fallback(file_id: str):
    return await get_telegram_file(file_id)
