import asyncio
from aiogram import Bot
from sqlalchemy import select
from database.db_connect import async_session_maker
from database.models import TgAccount
from config import BOT_TOKEN

async def main():
    bot = Bot(token=BOT_TOKEN)
    
    # You usually don't know the exact message_id of the last post natively without a user_client, 
    # but we can try fetching updates or assuming the owner forwards it.
    # Since we can't easily "get last channel message" with Bot API, we'll ask the bot to forward a specific known message ID, 
    # OR we can just ask the user to forward it to the bot once via the standard /broadcast owner panel.
    
    print("Please use the bot's /owner panel -> 'Keng qamrovli e'lon (Broadcast)' feature to send the post.")
    await bot.session.close()

if __name__ == "__main__":
    asyncio.run(main())
