from typing import List
from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.models.hero import Hero
from app.schemas.hero import Hero as HeroSchema, HeroCreate, HeroUpdate
from app.api.deps import get_current_user
import shutil
import os
from pathlib import Path
from app.core.config import settings

router = APIRouter()

@router.get("/", response_model=List[HeroSchema])
def get_heroes(db: Session = Depends(get_db)):
    heroes = db.query(Hero).all()
    return heroes

@router.get("/{hero_id}", response_model=HeroSchema)
def get_hero(hero_id: UUID, db: Session = Depends(get_db)):
    hero = db.query(Hero).filter(Hero.id == hero_id).first()
    if not hero:
        raise HTTPException(status_code=404, detail="Hero not found")
    return hero

@router.post("/", response_model=HeroSchema)
def create_hero(hero: HeroCreate, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    # Check if nickname already exists
    existing_hero = db.query(Hero).filter(Hero.nickname == hero.nickname).first()
    if existing_hero:
        raise HTTPException(status_code=400, detail="Nickname already exists")
    
    db_hero = Hero(**hero.dict())
    db.add(db_hero)
    db.commit()
    db.refresh(db_hero)
    return db_hero

@router.put("/{hero_id}", response_model=HeroSchema)
def update_hero(hero_id: UUID, hero: HeroUpdate, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    db_hero = db.query(Hero).filter(Hero.id == hero_id).first()
    if not db_hero:
        raise HTTPException(status_code=404, detail="Hero not found")
    
    # Check nickname uniqueness if being updated
    if hero.nickname and hero.nickname != db_hero.nickname:
        existing_hero = db.query(Hero).filter(Hero.nickname == hero.nickname).first()
        if existing_hero:
            raise HTTPException(status_code=400, detail="Nickname already exists")
    
    hero_data = hero.dict(exclude_unset=True)
    for field, value in hero_data.items():
        setattr(db_hero, field, value)
    
    db.commit()
    db.refresh(db_hero)
    return db_hero

@router.delete("/{hero_id}")
def delete_hero(hero_id: UUID, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    hero = db.query(Hero).filter(Hero.id == hero_id).first()
    if not hero:
        raise HTTPException(status_code=404, detail="Hero not found")
    
    db.delete(hero)
    db.commit()
    return {"message": "Hero deleted successfully"}

@router.post("/upload-image/{hero_id}")
async def upload_hero_image(hero_id: UUID, file: UploadFile = File(...), db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    hero = db.query(Hero).filter(Hero.id == hero_id).first()
    if not hero:
        raise HTTPException(status_code=404, detail="Hero not found")
    
    # Validate file type
    allowed_types = ["image/jpeg", "image/png", "image/gif", "image/webp"]
    if file.content_type not in allowed_types:
        raise HTTPException(status_code=400, detail="Invalid file type. Only images are allowed.")
    
    # Create uploads directory if it doesn't exist
    upload_dir = Path(settings.upload_dir)
    upload_dir.mkdir(exist_ok=True)
    
    # Generate unique filename
    file_extension = file.filename.split(".")[-1] if "." in file.filename else "jpg"
    filename = f"{hero_id}.{file_extension}"
    file_path = upload_dir / filename
    
    # Save file
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
    
    # Update hero with image path
    hero.profile_picture = f"/uploads/{filename}"
    db.commit()
    
    return {"message": "Image uploaded successfully", "filename": filename}