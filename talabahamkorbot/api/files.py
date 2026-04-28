from fastapi import APIRouter, HTTPException, Query
from fastapi.responses import Response
from bot import bot
import aiohttp
import logging

logger = logging.getLogger(__name__)
router = APIRouter()

async def fetch_tg_file(file_id: str):
    """Helper to fetch file from Telegram and return as bytes."""
    try:
        file = await bot.get_file(file_id)
        if not file.file_path:
            return None, "File path not found"

        token = bot.token
        file_url = f"https://api.telegram.org/file/bot{token}/{file.file_path}"
        
        async with aiohttp.ClientSession() as session:
            async with session.get(file_url) as resp:
                if resp.status != 200:
                    return None, "File not found on Telegram servers"
                body = await resp.read()
                return body, None
    except Exception as e:
        logger.error(f"Telegram Proxy Error: {e}")
        return None, str(e)


@router.get("/proxy")
async def get_telegram_file_proxy(file_id: str = Query(...)):
    """Backend compatibility endpoint for query-param based file requests."""
    body, error = await fetch_tg_file(file_id)
    if error:
        raise HTTPException(status_code=500 if "Error" in error else 404, detail=error)
    return Response(content=body, media_type="image/jpeg")


@router.get("/{file_id}")
async def get_telegram_file(file_id: str):
    """Standard RESTful endpoint for file retrieval."""
    body, error = await fetch_tg_file(file_id)
    if error:
        raise HTTPException(status_code=500 if "Error" in error else 404, detail=error)
    return Response(content=body, media_type="image/jpeg")


# Fallback alias for Flutter bug where /api/v1 is appended twice
@router.get("/api/v1/files/{file_id}")
async def get_telegram_file_fallback(file_id: str):
    return await get_telegram_file(file_id)
