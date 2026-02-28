import asyncio
from database.db_connect import AsyncSessionLocal
from sqlalchemy import text
import builtins
import sys

async def generate():
    async with AsyncSessionLocal() as db:
        res = await db.execute(text("""
            SELECT 
                COALESCE(u.university_name, s.university_name, 'Nomalum Universitet') as university_name, 
                COALESCE(u.faculty_name, s.faculty_name, 'Nomalum Fakultet') as faculty_name, 
                COUNT(u.id) as count 
            FROM users u
            LEFT JOIN students s ON u.hemis_login = s.hemis_login
            WHERE u.role = 'student'
            GROUP BY COALESCE(u.university_name, s.university_name, 'Nomalum Universitet'), COALESCE(u.faculty_name, s.faculty_name, 'Nomalum Fakultet')
            ORDER BY count DESC;
        """))
        rows = res.fetchall()
        
        res_staff = await db.execute(text("""
            SELECT role, COUNT(id) as count FROM staff 
            WHERE username IS NOT NULL OR telegram_id IS NOT NULL OR jshshir IS NOT NULL
            GROUP BY role ORDER BY count DESC;
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

    with builtins.open('output_filtered2.txt', 'w', encoding='utf-8') as f:
        f.write("# Tizim Foydalanuvchilari Hisoboti (Aniqlashtirilgan Loginlar)\n\n")
        f.write(f"**Umumiy talabalar soni (Faqatgina to'liq avtorizatsiyadan o'tganlar):** {total_students}\n")
        f.write("> **Eslatma:** Platformangizni yuklab olganlar soni (3000+) Play Market/App Store dagi o'rnatishlar soni bo'lib, ular dasturni ochgani bilan hammasi ham tizimga HEMIS orqali login qila olmagan. Ma'lumotlar bazasidagi `users` jadvalida bevosita tizimga kirib akkaunt ochganlar aniq **{total_students}** nafarni tashkil etadi.\n\n")
        
        f.write(f"**Umumiy xodimlar soni:** {total_staff}\n\n")
        
        f.write("## 🏛 Universitetlar va Fakultetlar bo'yicha (Talabalar)\n\n")
        
        sorted_univs = sorted(universities.items(), key=lambda x: sum(item[1] for item in x[1]), reverse=True)
        
        for u_name, faculties in sorted_univs:
            u_total = sum(item[1] for item in faculties)
            f.write(f"### {u_name} (Jami: {u_total})\n")
            for f_name, count in sorted(faculties, key=lambda x: x[1], reverse=True):
                f.write(f"- {f_name}: {count}\n")
            f.write("\n")
            
        f.write("## 👨‍💼 Xodimlar roliklari bo'yicha\n\n")
        for role, count in staff_rows:
            f.write(f"- **{role.capitalize()}**: {count}\n")
        
        f.write("\n---\n\n")
        f.write(f"**Qamrab olingan universitetlar soni: {len(universities)} ta**\n")

if __name__ == '__main__':
    asyncio.run(generate())
