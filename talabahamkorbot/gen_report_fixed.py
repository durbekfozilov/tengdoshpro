import asyncio
from database.db_connect import AsyncSessionLocal
from sqlalchemy import text
import builtins

async def generate():
    async with AsyncSessionLocal() as db:
        res = await db.execute(text("""
            SELECT 
                COALESCE(u.name, 'Nomalum Universitet') as university_name, 
                COALESCE(f.name, 'Nomalum Fakultet') as faculty_name, 
                COUNT(s.id) as count 
            FROM students s 
            LEFT JOIN universities u ON s.university_id = u.id 
            LEFT JOIN faculties f ON s.faculty_id = f.id 
            GROUP BY u.name, f.name 
            ORDER BY count DESC, u.name, f.name;
        """))
        rows = res.fetchall()
        
        res_staff = await db.execute(text("""
            SELECT role, COUNT(id) as count FROM staff GROUP BY role ORDER BY count DESC;
        """))
        staff_rows = res_staff.fetchall()

    universities = {}
    total_students = 0
    for u_name, f_name, count in rows:
        if u_name not in universities:
            universities[u_name] = []
        universities[u_name].append((f_name, count))
        total_students += count

    total_staff = sum(row[1] for row in staff_rows)

    with builtins.open('output.txt', 'w') as f:
        f.write("# Tizim Foydalanuvchilari Hisoboti\n\n")
        f.write(f"**Umumiy talabalar soni:** {total_students}\n\n")
        f.write(f"**Umumiy xodimlar soni:** {total_staff}\n\n")
        
        f.write("## 🏛 Universitetlar va Fakultetlar bo'yicha (Talabalar)\n\n")
        
        # Sort universities by total students descending
        sorted_univs = sorted(universities.items(), key=lambda x: sum(item[1] for item in x[1]), reverse=True)
        
        for u_name, faculties in sorted_univs:
            u_total = sum(item[1] for item in faculties)
            f.write(f"### {u_name} (Jami: {u_total})\n")
            # Sort faculties by count descending
            for f_name, count in sorted(faculties, key=lambda x: x[1], reverse=True):
                f.write(f"- {f_name}: {count}\n")
            f.write("\n")
            
        f.write("## 👨‍💼 Xodimlar roliklari bo'yicha\n\n")
        for role, count in staff_rows:
            f.write(f"- **{role.capitalize()}**: {count}\n")

if __name__ == '__main__':
    asyncio.run(generate())
