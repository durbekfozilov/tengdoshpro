import asyncio
import io
import importlib

async def test():
    bot_module = importlib.import_module("bot")
    bot = bot_module.bot
    print(dir(bot))
    print(bot.download.__doc__)

asyncio.run(test())
