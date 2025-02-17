from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .endpoints import router
from .database import init_db
import pickle
import numpy as np
from sklearn.ensemble import RandomForestClassifier

app = FastAPI()

# Load model at startup
@app.on_event("startup")
async def load_model():
    global model
    try:
        with open('ml_api/models/cardio_model.pkl', 'rb') as file:
            model = pickle.load(file)
        print(f"Model loaded successfully. Type: {type(model)}")
    except Exception as e:
        print(f"Error loading model: {e}")

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
