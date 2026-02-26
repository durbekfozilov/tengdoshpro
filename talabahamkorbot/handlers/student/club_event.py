from aiogram import Router, F
from aiogram.types import Message, ReplyKeyboardRemove
from aiogram.fsm.context import FSMContext
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
import logging

from models.states import ClubEventActivityState
from database.models import (
    ClubEvent, ClubEventParticipant, ClubEventImage
)

router = Router()
logger = logging.getLogger(__name__)

@router.message(ClubEventActivityState.waiting_for_photo, F.photo | F.document | F.text)
async def process_club_event_photo(message: Message, state: FSMContext, session: AsyncSession):
    data = await state.get_data()
    event_id = data.get("club_event_id")
    uploaded_photos = data.get("uploaded_photos", [])
    
    if message.text == "✅ Yakunlash":
        # Process the uploaded photos and mark activity
        if not uploaded_photos:
            await message.answer("Siz hech qanday rasm yuklamadingiz. Kamida bitta rasm yuklang.")
            return
            
        ev = await session.get(ClubEvent, event_id)
        if not ev:
            await message.answer("Tadbir o'chirilgan yoki topilmadi.", reply_markup=ReplyKeyboardRemove())
            await state.clear()
            return
            
        # Check if photos already exist and replace or append
        # Let's delete old photos for this event, or just append. 
        # Appending is safer, but maybe delete old so user can re-upload? Let's delete old.
        from sqlalchemy import delete
        await session.execute(delete(ClubEventImage).where(ClubEventImage.event_id == event_id))
        
        for photo_id in uploaded_photos:
            img = ClubEventImage(event_id=event_id, file_id=photo_id)
            session.add(img)
            
        await session.commit()
        await message.answer(
            f"✅ <b>Muvaffaqiyatli!</b>\n\n"
            f"Jami {len(uploaded_photos)} ta rasm tadbirga saqlandi.\n"
            f"Endi <b>mobil ilovaga qaytib</b> qatnashchilarni belgilang va 'Saqlash' tugmasini bosing.",
            parse_mode="HTML",
            reply_markup=ReplyKeyboardRemove()
        )
        await state.clear()
        return

    # Cancel command check
    if message.text == "/cancel" or (message.text and message.text.lower() == "bekor qilish"):
        await state.clear()
        await message.answer("Tadbir faolligini yakunlash bekor qilindi.", reply_markup=ReplyKeyboardRemove())
        return

    # Handle photo upload
    file_id = None
    if message.photo:
        file_id = message.photo[-1].file_id
    elif message.document and getattr(message.document, 'mime_type', '').startswith('image/'):
        file_id = message.document.file_id
        
    if not file_id:
        await message.answer("Iltimos faqat rasm yuboring, yoki tugatish uchun \"✅ Yakunlash\" tugmasini bosing.")
        return
        
    if len(uploaded_photos) >= 5:
        await message.answer("Siz maksimal 5 ta rasm yuklab bo'ldingiz. Iltimos \"✅ Yakunlash\" tugmasini bosing.")
        return
        
    uploaded_photos.append(file_id)
    await state.update_data(uploaded_photos=uploaded_photos)
    
    await message.answer(f"✅ Rasm qabul qilindi ({len(uploaded_photos)}/5).\n\nYana rasm yuborishingiz yoki jarayonni yakunlashingiz mumkin.")
