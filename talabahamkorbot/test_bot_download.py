import asyncio
from bot import bot
from config import BOT_TOKEN

async def test():
    # just print the bot download method documentation
    print(bot.download.__doc__)

asyncio.run(test())
