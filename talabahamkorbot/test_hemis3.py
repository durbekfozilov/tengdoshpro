import asyncio
from services.hemis_service import HemisService

async def main():
    from config import HEMIS_ADMIN_TOKEN
    import httpx
    
    client = httpx.AsyncClient(verify=False)
    url = "https://student.jmcu.uz/rest/v1/data/employee-list"
    headers = HemisService.get_headers(HEMIS_ADMIN_TOKEN)
    
    params = {"type": "all", "limit": 10, "search": "Nurjaxon"}
    response = await client.get(url, headers=headers, params=params)
    if response.status_code == 200:
        data = response.json()
        items = data.get("data", {}).get("items", [])
        for item in items:
            print(f"Name: {item.get('full_name')}, ID: {item.get('employee_id_number')}, PINFL: {item.get('pinfl') or item.get('jshshir')}")
    else:
        print(f"Error: {response.status_code}")

if __name__ == "__main__":
    asyncio.run(main())
