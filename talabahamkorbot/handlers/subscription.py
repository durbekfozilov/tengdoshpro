from aiogram import Router, F
from aiogram.types import CallbackQuery
from aiogram.fsm.context import FSMContext
from sqlalchemy.ext.asyncio import AsyncSession
from handlers.deep_link_auth import process_deep_link, process_generic_start

router = Router()

@router.callback_query(F.data == "check_subscription")
async def cb_check_subscription(call: CallbackQuery, state: FSMContext, session: AsyncSession):
    """
    Agar middleware o'tkazib yuborgan bo'lsa, demak foydalanuvchi a'zo bo'lgan.
    Zaxiradagi command bormi tekshiramiz va davom ettiramiz.
    """
    data = await state.get_data()
    pending_command = data.get("pending_start_command")
    
    await call.message.delete()
    
    if pending_command:
        # pending_command: "/start payload" or "/start"
        # Clear it first to avoid loops
        await state.update_data(pending_start_command=None)
        
        args = ""
        if " " in pending_command:
            args = pending_command.split(" ", 1)[1]
        
        if args:
            await process_deep_link(call.message, args, session, state, user_id=call.from_user.id)
        else:
            await process_generic_start(call.message, state, session, user_id=call.from_user.id)
    else:
        await call.message.answer("✅ Rahmat! Boshlash uchun quyidagi tugmani bosing:\n\n👉 /start")
    
    await call.answer()
