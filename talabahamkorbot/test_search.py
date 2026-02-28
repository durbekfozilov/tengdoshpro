import asyncio
from config import HEMIS_ADMIN_TOKEN
from services.hemis_service import HemisService
import logging
import httpx

logging.basicConfig(level=logging.INFO)

async def test_search():
    client = await HemisService.get_client()
    url = f"https://student.jmcu.uz/rest/v1/data/employee-list"
    headers = HemisService.get_headers(HEMIS_ADMIN_TOKEN)
    
    # Let's search for something that might be a substring
    identifier = "1"
    params = {"type": "all", "limit": 10, "search": str(identifier)}

    res = await client.get(url, headers=headers, params=params)
    data = res.json()
    items = data.get("data", {}).get("items", [])
    print(f"Items found: {len(items)}")
    for item in items:
        print(f"ID: {item.get('employee_id_number')} Name: {item.get('short_name')}")

asyncio.run(test_search())
