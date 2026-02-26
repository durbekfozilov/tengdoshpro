import csv
from collections import defaultdict
import os

file_path = "/home/user/talabahamkor/talabahamkorbot/scripts/login_stats_report.csv"

if not os.path.exists(file_path):
    print("Xatolik: Hisobot fayli topilmadi. Avval generate_login_report.py ni ishga tushiring.")
    exit(1)

total_students = 0
total_logged_in = 0
total_missing = 0

faculty_stats = defaultdict(lambda: {"total": 0, "logged_in": 0, "missing": 0})

with open(file_path, 'r', encoding='utf-8-sig') as f:
    reader = csv.DictReader(f)
    for row in reader:
        faculty = row["Fakultet"]
        total = int(row["Jami Talaba (HEMIS)"])
        logged_in = int(row["Ilovaga kirganlar"])
        missing = int(row["Kirmaganlar soni"])
        
        total_students += total
        total_logged_in += logged_in
        total_missing += missing
        
        faculty_stats[faculty]["total"] += total
        faculty_stats[faculty]["logged_in"] += logged_in
        faculty_stats[faculty]["missing"] += missing

md = "## 📊 TalabaHamkor Bosh Hisoboti\n\n"
md += "### Umumiy Ko'rsatkichlar\n"
md += f"- **Jami Talabalar (HEMIS):** {total_students} ta\n"
md += f"- **Ilovaga Kirganlar:** {total_logged_in} ta\n"
md += f"- **Ilovaga Kirmaganlar:** {total_missing} ta\n"
md += f"📈 **Faollik foizi:** {round((total_logged_in / total_students) * 100, 1) if total_students > 0 else 0}%\n\n"

md += "### Fakultetlar Kesimida:\n\n"
md += "| Fakultet | Jami | Kirganlar | Kirmaganlar | Faollik (%) |\n"
md += "|----------|------|-----------|-------------|-------------|\n"

for faculty, stats in sorted(faculty_stats.items(), key=lambda x: x[1]["logged_in"], reverse=True):
    total = stats["total"]
    percent = round((stats["logged_in"] / total) * 100, 1) if total > 0 else 0
    md += f"| {faculty} | {total} | {stats['logged_in']} | {stats['missing']} | {percent}% |\n"

print(md)
