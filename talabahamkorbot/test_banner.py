import asyncio
import requests
from database.db_connect import AsyncSessionLocal
from database.models import Banner
from sqlalchemy import select

async def main():
    async with AsyncSessionLocal() as session:
        res = await session.execute(select(Banner).where(Banner.is_active==True).order_by(Banner.id.desc()).limit(1))
        banner = res.scalar_one_or_none()
        
        if not banner:
            print("No active banner found.")
            return
            
        print(f"Banner #{banner.id} initial views: {banner.views}, clicks: {banner.clicks}")
        print("Sending 3 view requests...")
        for _ in range(3):
            requests.get("http://127.0.0.1:8000/api/v1/banner/active")
            
        print("Sending 2 click requests...")
        for _ in range(2):
            requests.post(f"http://127.0.0.1:8000/api/v1/banner/click/{banner.id}")
            
        await session.refresh(banner)
        print(f"Banner #{banner.id} final views: {banner.views}, clicks: {banner.clicks}")

asyncio.run(main())
