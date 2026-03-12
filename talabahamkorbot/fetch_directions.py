import aiohttp
import asyncio
from sqlalchemy import select
from database.config import async_session
from database.models import Student

async def fetch():
    async with async_session() as db:
        student = await db.scalar(select(Student).where(Student.hemis_login == "395251101411"))
        token = getattr(student, "hemis_token", None)
        if not token:
            print("NO TOKEN in ClassVar. This requires login. Try fetching from cache or user db if saved.")
            return
            
    url = "https://student.jmcu.uz/rest/v1/social-activity/directions"
    headers = {"Authorization": f"Bearer {token}", "Accept": "application/json"}
    
    async with aiohttp.ClientSession() as session:
        async with session.get(url, headers=headers) as resp:
            data = await resp.json()
            import json
            print(json.dumps(data, indent=2))

if __name__ == "__main__":
    asyncio.run(fetch())
