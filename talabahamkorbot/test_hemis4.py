import asyncio
from services.hemis_service import HemisService
from config import HEMIS_ADMIN_TOKEN
import json

async def main():
    client = await HemisService.get_client()
    url = "https://student.jmcu.uz/rest/v1/data/employee-list"
    headers = HemisService.get_headers(HEMIS_ADMIN_TOKEN)
    
    print("Requesting with passport_pin=12345678901234")
    response = await client.get(url, headers=headers, params={"type": "all", "limit": 1, "passport_pin": "12345678901234"})
    print("Result items:", len(response.json().get("data", {}).get("items", [])))
    
    print("Requesting with search=12345678901234")
    response2 = await client.get(url, headers=headers, params={"type": "all", "limit": 1, "search": "12345678901234"})
    print("Result items:", len(response2.json().get("data", {}).get("items", [])))

    print("Requesting with search=3952612024")
    response3 = await client.get(url, headers=headers, params={"type": "all", "limit": 1, "search": "3952612024"})
    print("Result items:", len(response3.json().get("data", {}).get("items", [])))

asyncio.run(main())
