import numpy as np
import pandas as pd
import pickle
from fastapi import APIRouter, HTTPException, Depends
from health_data import HealthDataInput, PredictionResponse
from mongodb import save_prediction, get_db_connection
from typing import List, Optional
from config import MODEL_PATH
from datetime import datetime, timedelta
from motor.motor_asyncio import AsyncIOMotorDatabase

router = APIRouter()

try:
    with open(MODEL_PATH, 'rb') as file:
        model_data = pickle.load(file)
        model = model_data['model']
        scaler = model_data['scaler']
        feature_name = model_data['feature_name']
except Exception as e:
    print(f"Error loading model: {e}")


@router.post("/predict", response_model=PredictionResponse)
async def predict(data: HealthDataInput):
    try:
        features_df = pd.DataFrame([[
            data.age,
            data.gender,
            data.height,
            data.weight,
            data.bmi,
            data.ap_hi,
            data.ap_lo,
            data.cholesterol,
            data.gluc,
            data.smoke,
            data.alco,
            data.active
        ]], columns=feature_name)
        print(f"Input features: {features_df}")

        features_scaled = scaler.transform(features_df)
        prediction = model.predict(features_scaled)[0]
        try:
            probability = model.predict_proba(features_scaled)[0][1]
        except AttributeError:
            probability = None
        
        await save_prediction(data, int(prediction), probability)
        
        return PredictionResponse(
            cardio_risk=int(prediction),
            probability=float(probability) if probability is not None else 0.0
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/predict/from-mongodb/{user_id}")
async def predict_from_mongodb(user_id: str):
    """Fetch the latest health data for a user from MongoDB and make the prediction"""
    async with get_db_connection() as db:
        health_data = await db.health_data.find_one(
            {"user_id": user_id},
            sort=[("timestamp", -1)]
        )

        if not health_data:
            raise HTTPException(status_code=404, detail=f"No health data found for user {user_id}")

        input_data = HealthDataInput(
            age=health_data.get("age"),
            gender=health_data.get("gender"),
            height=health_data.get("height"),
            weight=health_data.get("weight"),
            bmi=health_data.get("bmi"),
            ap_hi=health_data.get("ap_hi"),
            ap_lo=health_data.get("ap_lo"),
            cholesterol=health_data.get("cholesterol"),
            gluc=health_data.get("gluc"),
            smoke=health_data.get("smoke"),
            alco=health_data.get("alco"),
            active=health_data.get("active")
        )

        features = np.array([[
            input_data.age,
            input_data.gender,
            input_data.height,
            input_data.weight,
            input_data.bmi,
            input_data.ap_hi,
            input_data.ap_lo,
            input_data.cholesterol,
            input_data.gluc,
            input_data.smoke,
            input_data.alco,
            input_data.active
        ]])

        features_scaled = scaler.transform(features)
        prediction = model.predict(features_scaled)[0]

        try:
            probability = model.predict_proba(features_scaled)[0][1]
        except AttributeError:
            probability = None
        
        await save_prediction(input_data, prediction, probability)

        return PredictionResponse(
            cardio_risk=int(prediction),
            probability=float(probability) if probability is not None else 0.0
        )

@router.get("/batch-predict")
async def batch_predict():
    """Run predictions for all users with health data updated in the last 24 hours"""
    async with get_db_connection() as db:
        yesterday = datetime.now() - timedelta(days=1)

        cursor = db.health_data.find({
            "timestamp": {"$gte": yesterday.isoformat()}
        })

        results = []
        async for health_data in cursor:
            user_id = health_data.get("user_id")
            
            input_data = HealthDataInput(
                age=health_data.get("age"),
                gender=health_data.get("gender"),
                height=health_data.get("height"),
                weight=health_data.get("weight"),
                bmi=health_data.get("bmi"),
                ap_hi=health_data.get("ap_hi"),
                ap_lo=health_data.get("ap_lo"),
                cholesterol=health_data.get("cholesterol"),
                gluc=health_data.get("gluc"),
                smoke=health_data.get("smoke"),
                alco=health_data.get("alco"),
                active=health_data.get("active")
            )
            
            features = np.array([[
                input_data.age,
                input_data.gender,
                input_data.height,
                input_data.weight,
                input_data.bmi,
                input_data.ap_hi,
                input_data.ap_lo,
                input_data.cholesterol,
                input_data.gluc,
                input_data.smoke,
                input_data.alco,
                input_data.active
            ]])
            
            features_scaled = scaler.transform(features)
            prediction = model.predict(features_scaled)[0]

            try:
                probability = model.predict_proba(features_scaled)[0][1]
            except AttributeError:
                probability = None
            
            await save_prediction(input_data, prediction, probability)

            results.append({
                "user_id": user_id,
                "cardio_risk": int(prediction),
                "probability": float(probability) if probability is not None else 0.0
            })

        return {"predictions": results}
