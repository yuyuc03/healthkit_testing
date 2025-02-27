from fastapi import FastAPI, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from endpoints import router
from mongodb import init_db, get_db_connection
from motor.motor_asyncio import AsyncIOMotorClient
import pickle
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from config import MODEL_PATH
import asyncio
import time
from datetime import datetime, timedelta
import certifi

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

MONGO_URI = "mongodb+srv://yuyucheng2003:2yjbDeyUfi2GF8KI@healthmetrics.z6rit.mongodb.net/?retryWrites=true&w=majority&appName=HealthMetrics"
DB_NAME = "health_metrics"

@app.on_event("startup")
async def startup_event():
    app.mongodb_client = AsyncIOMotorClient(
        MONGO_URI,
        tlsCAFile=certifi.where()
    )
    app.mongodb = app.mongodb_client[DB_NAME]
    print("Connected to MongoDB!")

    await init_db()

    asyncio.create_task(scheduled_batch_predictions())

async def scheduled_batch_predictions():
    while True:
        try:
            db = app.mongodb
            yesterday = datetime.now() - timedelta(days=1)
            
            cursor = db.health_data.find({
                "timestamp": {"$gte": yesterday.isoformat()}
            })

            with open(MODEL_PATH, 'rb') as file:
                model_data = pickle.load(file)
                model = model_data['model']
                scaler = model_data['scaler']
            
            async for health_data in cursor:
                features = np.array([[
                    health_data.get("age"),
                    health_data.get("gender"),
                    health_data.get("height"),
                    health_data.get("weight"),
                    health_data.get("bmi"),
                    health_data.get("ap_hi"),
                    health_data.get("ap_lo"),
                    health_data.get("cholesterol"),
                    health_data.get("gluc"),
                    health_data.get("smoke"),
                    health_data.get("alco"),
                    health_data.get("active")
                ]])

                features_scaled = scaler.transform(features)
                prediction = model.predict(features_scaled)[0]

                try:
                    probability = model.predict_proba(features_scaled)[0][1]
                except AttributeError:
                    probability = None
                
                # Save prediction to MongoDB
                await db.predictions.insert_one({
                    "user_id": health_data.get("user_id"),
                    "timestamp": datetime.now().isoformat(),
                    "prediction": int(prediction),
                    "probability": float(probability) if probability is not None else 0.0,
                    "health_data_id": health_data.get("_id")
                })
            
            print("Scheduled batch predictions completed")

        except Exception as e:
            print(f"Error in scheduled batch predictions: {e}")
        
        await asyncio.sleep(60)

@app.on_event("shutdown")
async def shutdown_event():
    app.mongodb_client.close()
    print("MongoDB connection closed")

app.include_router(router, prefix="/api/v1")