import asyncio
import os
import sys

sys.path.append(os.path.dirname(os.path.abspath(__file__)) + "/..")

from config import OWNER_TELEGRAM_ID
from bot import bot
from aiogram.types import FSInputFile

async def send_report():
    file_path = "/home/user/talabahamkor/talabahamkorbot/scripts/login_stats_report.csv"
    if not os.path.exists(file_path):
        print("File not found")
        return
        
    try:
        document = FSInputFile(file_path, filename="Logindan_o_tgan_talabalar_xisoboti.csv")
        caption = "📊 Fakultet, yo'nalish, guruh va tyutorlar kesimida ilovadan qanday foydalanilayotgani bo'yicha hisobot.\n\nFaylni Excel dasturi orqali ochib bemalol filtrlashingiz mumkin."
        
        await bot.send_document(
            chat_id=OWNER_TELEGRAM_ID,
            document=document,
            caption=caption
        )
        print("Report sent to admin successfully.")
    except Exception as e:
        print(f"Error: {e}")
    finally:
        await bot.session.close()

if __name__ == "__main__":
    asyncio.run(send_report())
