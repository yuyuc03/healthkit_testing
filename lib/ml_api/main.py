from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .endpoints import router
from .database import init_db
import pickle
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from .config import MODEL_PATH

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("startup")
async def startup_event():
    init_db()

app.include_router(router, prefix="/api/v1")