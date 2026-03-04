from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from pydantic import BaseModel
from typing import Optional

from database.db_connect import get_session
from database.models import AppConfig, Student
from api.dependencies import get_db, get_owner

router = APIRouter()

class AppConfigResponse(BaseModel):
    min_version: str
    latest_version: str
    force_update: bool
    update_url_android: Optional[str]
    update_url_ios: Optional[str]
    maintenance_mode: bool

class AppConfigUpdate(BaseModel):
    min_version: str
    latest_version: str
    force_update: bool
    update_url_android: Optional[str]
    update_url_ios: Optional[str]
    maintenance_mode: bool

@router.get("/mobile", response_model=AppConfigResponse)
async def get_mobile_config(db: AsyncSession = Depends(get_db)):
    """
    Public endpoint for the Flutter app to check for forced updates or maintenance mode
    on the splash screen.
    """
    res = await db.execute(select(AppConfig).limit(1))
    config = res.scalar_one_or_none()
    
    if not config:
        # Fallback if table is somehow empty
        return {
            "min_version": "1.0.0",
            "latest_version": "1.0.0",
            "force_update": False,
            "update_url_android": "https://play.google.com/store/apps/details?id=com.talaba.hamkor",
            "update_url_ios": "https://apps.apple.com/app/id123456789",
            "maintenance_mode": False
        }
        
    return {
        "min_version": config.min_version,
        "latest_version": config.latest_version,
        "force_update": config.force_update,
        "update_url_android": config.update_url_android,
        "update_url_ios": config.update_url_ios,
        "maintenance_mode": config.maintenance_mode
    }

@router.post("/management")
async def update_mobile_config(
    data: AppConfigUpdate,
    admin: Student = Depends(get_owner),
    db: AsyncSession = Depends(get_db)
):
    """
    Admin endpoint to change the App Config remotely.
    """
    res = await db.execute(select(AppConfig).limit(1))
    config = res.scalar_one_or_none()
    
    if not config:
        config = AppConfig(id=1)
        db.add(config)
        
    config.min_version = data.min_version
    config.latest_version = data.latest_version
    config.force_update = data.force_update
    config.update_url_android = data.update_url_android
    config.update_url_ios = data.update_url_ios
    config.maintenance_mode = data.maintenance_mode
    
    await db.commit()
    
    return {"success": True, "message": "Ilova sozlamalari muvaffaqiyatli saqlandi!"}
