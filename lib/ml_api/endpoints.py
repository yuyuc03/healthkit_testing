import numpy as np
import pickle
from fastapi import APIRouter, HTTPException
from .health_data import HealthDataInput, PredictionResponse
from .database import save_prediction
from .config import MODEL_PATH

router = APIRouter()

try:
    with open(MODEL_PATH, 'rb') as file:
        model_data = pickle.load(file)
        model = model_data['model']
        scaler = model_data['scaler']
        feature_names = model_data['feature_names']
except Exception as e:
    print(f"Error loading model: {e}")


@router.post("/predict", response_model=PredictionResponse)
async def predict(data: HealthDataInput):
    try:
        # Prepare features
        features = np.array([[
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
        ]])
        print(f"Input features: {features}")

        features_scaled = scaler.transform(features)
        
        prediction = model.predict(features_scaled)[0]
        try:
            probability = model.predict_proba(features_scaled)[0][1]
        except AttributeError:
            probability = None
        
        save_prediction(data, prediction, probability)
        
        return PredictionResponse(
            cardio_risk=int(prediction),
            probability=float(probability)
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))