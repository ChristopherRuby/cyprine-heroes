from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from app.api.endpoints import heroes, auth
from app.core.config import settings
import os

app = FastAPI(
    title="Les héros de la Cyprine API",
    description="API pour gérer les héros de la Cyprine",
    version="1.0.0"
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://localhost:5173"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount static files for uploads
if os.path.exists(settings.upload_dir):
    app.mount("/uploads", StaticFiles(directory=settings.upload_dir), name="uploads")

# Include routers
app.include_router(auth.router, prefix="/api/auth", tags=["authentication"])
app.include_router(heroes.router, prefix="/api/heroes", tags=["heroes"])

@app.get("/")
def read_root():
    return {"message": "Les héros de la Cyprine API is running!"}