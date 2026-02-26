import asyncio
import httpx
import csv
import os
import sys

# Add parent dir to path so we can import app modules
sys.path.append(os.path.dirname(os.path.abspath(__file__)) + "/..")

from config import HEMIS_ADMIN_TOKEN
from database.db_connect import AsyncSessionLocal
from database.models import Student, TutorGroup, Staff
from sqlalchemy import select

async def get_tutor_mapping():
    async with AsyncSessionLocal() as db:
        result = await db.execute(
            select(TutorGroup.group_number, Staff.full_name)
            .join(Staff, TutorGroup.tutor_id == Staff.id)
        )
        return {row.group_number: row.full_name for row in result.all()}

async def get_local_students():
    async with AsyncSessionLocal() as db:
        result = await db.execute(select(Student.hemis_id))
        return {str(row[0]) for row in result.all() if row[0]}

async def fetch_hemis_students():
    client = httpx.AsyncClient(verify=False, timeout=30.0)
    headers = {"Authorization": f"Bearer {HEMIS_ADMIN_TOKEN}"}
    students = []
    page = 1
    
    print("Fetcing students from HEMIS...")
    while True:
        url = f"https://student.jmcu.uz/rest/v1/data/student-list?limit=200&page={page}"
        try:
            resp = await client.get(url, headers=headers)
            if resp.status_code != 200:
                print(f"Error fetching page {page}: {resp.status_code}")
                break
                
            data = resp.json().get("data", {})
            items = data.get("items", [])
            
            if not items:
                break
                
            students.extend(items)
            print(f"Fetched page {page} ({len(items)} items). Total: {len(students)}")
            
            page_count = data.get("pagination", {}).get("pageCount", 1)
            if page >= page_count:
                break
            page += 1
        except Exception as e:
            print(f"Exception on page {page}: {e}")
            break
            
    await client.aclose()
    return students

async def generate_report():
    tutor_mapping = await get_tutor_mapping()
    local_student_ids = await get_local_students()
    hemis_students = await fetch_hemis_students()
    
    # Structure: stats[(faculty, specialty, group, tutor)] = {total: 0, lg: 0, missing: []}
    stats = {}
    
    for s in hemis_students:
        state = s.get("studentStatus", {}).get("name", "")
        # Filter active students if needed? User didn't specify, but usually we only care about active.
        if "Talabalar safidan chetlashtirilgan" in state or "Akademik ta'til" in state:
            continue
            
        hemis_id = str(s.get("id"))
        full_name = s.get("full_name", s.get("short_name", "Noma'lum"))
        group = s.get("group", {}).get("name", "Noma'lum")
        faculty = s.get("faculty", {}).get("name", "Noma'lum")
        specialty = s.get("specialty", {}).get("name", "Noma'lum")
        tutor = tutor_mapping.get(group, "Biriktirilmagan")
        
        key = (faculty, specialty, group, tutor)
        if key not in stats:
            stats[key] = {"total": 0, "logged_in": 0, "missing": []}
            
        stats[key]["total"] += 1
        if hemis_id in local_student_ids:
            stats[key]["logged_in"] += 1
        else:
            stats[key]["missing"].append(full_name)
            
    # Write to CSV
    output_file = "/home/user/talabahamkor/talabahamkorbot/scripts/login_stats_report.csv"
    with open(output_file, 'w', encoding='utf-8-sig', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(["Fakultet", "Yo'nalish", "Guruh", "Tyutor", "Jami Talaba (HEMIS)", "Ilovaga kirganlar", "Kirmaganlar soni", "Kirmagan talabalar (F.I.SH)"])
        
        # Sort by faculty, specialty, group
        for key in sorted(stats.keys()):
            faculty, specialty, group, tutor = key
            val = stats[key]
            missing_count = val["total"] - val["logged_in"]
            missing_names = ", ".join(val["missing"])
            writer.writerow([
                faculty, specialty, group, tutor, 
                val["total"], val["logged_in"], missing_count, missing_names
            ])
            
    print(f"\nReport generated successfully: {output_file}")

if __name__ == "__main__":
    asyncio.run(generate_report())
