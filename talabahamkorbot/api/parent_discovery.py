from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List
from database.db_connect import get_session
from database.models import University
from pydantic import BaseModel

router = APIRouter()

class UniversitySchema(BaseModel):
    id: int
    uni_code: str
    name: str
    short_name: str
    api_url: str # Child server manzili (masalan, https://tengdosh.uzjoku.uz)
    is_active: bool

    class Config:
        from_attributes = True

@router.get("/list", response_model=List[UniversitySchema])
async def get_universities(db: AsyncSession = Depends(get_session)):
    """
    Mobil ilova uchun barcha faol universitetlar ro'yxatini va ularning API manzillarini beradi.
    """
    result = await db.execute(select(University).where(University.is_active == True))
    return result.scalars().all()

@router.post("/register")
async def register_university(
    data: UniversitySchema, 
    db: AsyncSession = Depends(get_session)
):
    """
    Yangi universitet (Child server)ni Parent tizimiga qo'shish.
    """
    new_uni = University(
        uni_code=data.uni_code,
        name=data.name,
        short_name=data.short_name,
        api_url=data.api_url,
        is_active=True
    )
    db.add(new_uni)
    await db.commit()
    return {"success": True, "message": f"{data.name} muvaffaqiyatli ro'yxatdan o'tdi."}
