import asyncio
from services.hemis_service import HemisService

async def main():
    from config import HEMIS_ADMIN_TOKEN
    import httpx
    
    client = httpx.AsyncClient(verify=False)
    url = "https://student.jmcu.uz/rest/v1/data/employee-list"
    headers = HemisService.get_headers(HEMIS_ADMIN_TOKEN)
    
    params = {"limit": 1}
    response = await client.get(url, headers=headers, params=params)
    print("Default call:", response.status_code)
    if response.status_code == 200:
        data = response.json()
        items = data.get("data", {}).get("items", [])
        if items:
            emp = items[0]
            print(f"Sample Employee fields: {list(emp.keys())}")
            print(f"Sample Employee ID Number: {emp.get('employee_id_number')}")
            print(f"Sample Employee PINFL: {emp.get('pinfl') or emp.get('passport_pin') or emp.get('jshshir')}")

            # Now test searching this specific employee by exact employee_id_number
            emp_id = emp.get('employee_id_number')
            resp2 = await client.get(url, headers=headers, params={"search": emp_id})
            data2 = resp2.json().get("data", {}).get("items", [])
            print(f"Search by search={emp_id}: Found {len(data2)} items")
            
            resp3 = await client.get(url, headers=headers, params={"employee_id_number": emp_id})
            data3 = resp3.json().get("data", {}).get("items", [])
            print(f"Search by employee_id_number={emp_id}: Found {len(data3)} items")
            
            # Since PINFL might be none, let's just try
            pinfl = emp.get('pinfl') or emp.get('passport_pin') or emp.get('jshshir')
            if pinfl:
                resp4 = await client.get(url, headers=headers, params={"search": pinfl})
                print(f"Search by search={pinfl}: Found {len(resp4.json().get('data', {}).get('items', []))} items")

if __name__ == "__main__":
    asyncio.run(main())
