from motor.motor_asyncio import AsyncIOMotorClient
from pymongo.server_api import ServerApi
from contextlib import asynccontextmanager
from datetime import datetime
from health_data import HealthDataInput
import certifi
import os

MONGO_URI = "mongodb+srv://yuyucheng2003:2yjbDeyUfi2GF8KI@healthmetrics.z6rit.mongodb.net/?retryWrites=true&w=majority&appName=HealthMetrics"
DB_NAME = "health_metrics"

@asynccontextmanager
async def get_db_connection():
    client = AsyncIOMotorClient(
        MONGO_URI,
        tlsCAFile=certifi.where()
    )
    try:
        yield client[DB_NAME]
    finally:
        client.close()

async def init_db():
    async with get_db_connection() as db:
        try:
            await db.command('ping')
            print("Successfully connected to MongoDB!")
        except Exception as e:
            print(f"MongoDB connection error: {e}")
            raise

async def save_prediction(data: HealthDataInput, prediction: int, probability: float):
    async with get_db_connection() as db:
        prediction_data = {
            "timestamp": datetime.now().isoformat(),
            "age": data.age,
            "gender": data.gender,
            "height": data.height,
            "weight": data.weight,
            "bmi": data.bmi,
            "ap_hi": data.ap_hi,
            "ap_lo": data.ap_lo,
            "cholesterol": data.cholesterol,
            "gluc": data.gluc,
            "smoke": data.smoke,
            "alco": data.alco,
            "active": data.active,
            "prediction": prediction,
            "probability": float(probability) if probability is not None else 0.0
        }
        await db.predictions.insert_one(prediction_data)
