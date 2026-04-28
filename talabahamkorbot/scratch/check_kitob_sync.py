import sqlite3
import os

db_path = "/home/user/talabahamkor/talabahamkorbot/database/app.db"

if not os.path.exists(db_path):
    print(f"DB not found at {db_path}")
    exit(1)

conn = sqlite3.connect(db_path)
cursor = conn.cursor()

try:
    cursor.execute("SELECT id, user_id, role_type, rating FROM rating_records WHERE role_type = 'kitobxonlik'")
    records = cursor.fetchall()
    print(f"Found {len(records)} kitobxonlik records")
    for r in records:
        print(f"ID: {r[0]}, StudentID: {r[1]}, Role: {r[2]}, Rating: {r[3]}")
        
    cursor.execute("SELECT id, role_type, title FROM rating_activations WHERE role_type = 'kitobxonlik'")
    acts = cursor.fetchall()
    print(f"Found {len(acts)} kitobxonlik activations")
    for a in acts:
        print(f"ID: {a[0]}, Role: {a[1]}, Title: {a[2]}")
except Exception as e:
    print(f"Error: {e}")
finally:
    conn.close()
