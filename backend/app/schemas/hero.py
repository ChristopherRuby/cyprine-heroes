from pydantic import BaseModel
from typing import Dict, Any, Optional
from datetime import datetime
from uuid import UUID

class HeroBase(BaseModel):
    firstname: str
    lastname: str
    nickname: str
    description: str
    profile_picture: Optional[str] = None
    skills: Dict[str, Any] = {}

class HeroCreate(HeroBase):
    pass

class HeroUpdate(HeroBase):
    firstname: Optional[str] = None
    lastname: Optional[str] = None
    nickname: Optional[str] = None
    description: Optional[str] = None

class Hero(HeroBase):
    id: UUID
    created_at: datetime
    updated_at: Optional[datetime]
    
    class Config:
        from_attributes = True