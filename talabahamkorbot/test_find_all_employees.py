import asyncio
from services.hemis_service import HemisService

async def main():
    from config import HEMIS_ADMIN_TOKEN
    import httpx
    
    client = httpx.AsyncClient(verify=False)
    url = "https://student.jmcu.uz/rest/v1/data/employee-list"
    headers = HemisService.get_headers(HEMIS_ADMIN_TOKEN)
    
    # We will fetch up to 3000 employees
    params = {"type": "all", "limit": 200, "page": 1}
    
    found_pinfl = None
    target_pinfl = "30808985740077"
    target_name = "Farmonov"
    
    for page in range(1, 10):
        params["page"] = page
        response = await client.get(url, headers=headers, params=params)
        if response.status_code != 200:
            break
            
        items = response.json().get("data", {}).get("items", [])
        if not items:
            break
            
        for item in items:
            p = item.get("pinfl") or item.get("jshshir") or item.get("passport_pin")
            n = item.get("full_name", "")
            if str(p) == target_pinfl:
                print(f"FOUND MATCHING PINFL: {n}, ID: {item.get('employee_id_number')}")
            if target_name.lower() in n.lower():
                print(f"FOUND MATCHING NAME: {n}, PINFL: {p}, ID: {item.get('employee_id_number')}")
                
    print("Done scanning employees.")

if __name__ == "__main__":
    asyncio.run(main())
