import asyncio
from services.hemis_service import HemisService

async def main():
    pinfl = "30808985740077"
    emp_id = "395191100477"
    
    # Try the real ID for Abror Juraqulov that the user mentioned earlier
    # Let's see if we can search by "Abror" to find him
    from config import HEMIS_ADMIN_TOKEN
    import httpx
    
    client = httpx.AsyncClient(verify=False)
    url = "https://student.jmcu.uz/rest/v1/data/employee-list"
    headers = HemisService.get_headers(HEMIS_ADMIN_TOKEN)
    
    # Search by Abror
    params = {"type": "all", "limit": 10, "search": "Abror"}
    response = await client.get(url, headers=headers, params=params)
    print("Search 'Abror':", response.status_code)
    if response.status_code == 200:
        data = response.json()
        items = data.get("data", {}).get("items", [])
        for item in items:
            print(f"Name: {item.get('full_name')}, ID: {item.get('employee_id_number')}, PINFL: {item.get('pinfl') or item.get('jshshir')}")

if __name__ == "__main__":
    asyncio.run(main())
