from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from pymongo import MongoClient
from datetime import datetime
import joblib
import os
import numpy as np
import certifi

app = FastAPI()

client = MongoClient("mongodb+srv://yuyucheng2003:2yjbDeyUfi2GF8KI@healthmetrics.z6rit.mongodb.net/?retryWrites=true&w=majority&appName=HealthMetrics", tlsCAFile=certifi.where())
prediction_db = client["health_metrics"]
health_metrics_db = client["test"]

prediction_collection = prediction_db["prediction"]
ml_model_data_collection = health_metrics_db["ml_model_data"]

model_path = os.path.join('ml_models', 'health_model.joblib')
model_data = joblib.load(model_path)
svm_model = model_data['model']
scaler = model_data['scaler']
feature_names = model_data['feature_name']
print(f"Loaded model type: {type(svm_model)}")
print(f"Loaded scaler type: {type(scaler)}")
print(f"Loaded feature names: {feature_names}")

class PredictionInput(BaseModel):
    timestamp: datetime
    user_id: str
    age: float
    gender: int
    height: float
    weight: float
    bmi: float
    ap_hi: float
    ap_lo: float
    cholesterol: int
    gluc: int
    smoke: int
    alco: int
    active: int

class PredictionOutput(BaseModel):
    prediction: float
    risk_probability: float

@app.post("/predict", response_model=PredictionOutput)
async def predict():
    try:
        latest_data = ml_model_data_collection.find_one(sort=[("timestamp", -1)])
        print(f"Latest data: {latest_data}")

        if not latest_data:
            raise HTTPException(status_code=404, detail="No data found in the ml_model_data collection")

        input_data = np.array([[
            latest_data["age"],
            latest_data["gender"],
            latest_data["height"],
            latest_data["weight"],
            latest_data["bmi"],
            latest_data["ap_hi"],
            latest_data["ap_lo"],
            latest_data["cholesterol"],
            latest_data["gluc"],
            latest_data["smoke"],
            latest_data["alco"],
            latest_data["active"]
        ]])
        print(f"Input data shape: {input_data.shape}")

        try:
            scaled_input = scaler.transform(input_data)
            probabilities = svm_model.predict_proba(scaled_input)[0]
            risk_probability = probabilities[1]  # Assuming 1 is the positive class
            prediction = 1 if risk_probability > 0.5 else 0
            print(f"Prediction: {prediction}, Risk Probability: {risk_probability}")
        except Exception as model_error:
            print(f"Error during model prediction: {str(model_error)}")
            raise HTTPException(status_code=500, detail=f"Model prediction error: {str(model_error)}")

        prediction_store = {
            "prediction": float(prediction),
            "risk_probability": float(risk_probability),
            "input_data": {k: v for k, v in latest_data.items() if k != '_id'}
        }
        
        try:
            prediction_collection.insert_one(prediction_store)
            print("Prediction stored successfully")
        except Exception as db_error:
            print(f"Error storing prediction: {str(db_error)}")
            raise HTTPException(status_code=500, detail=f"Database error: {str(db_error)}")

        return PredictionOutput(prediction=float(prediction), risk_probability=float(risk_probability))
    except Exception as e:
        print(f"Unexpected error in predict endpoint: {str(e)}")
        raise HTTPException(status_code=500, detail=f"An unexpected error occurred: {str(e)}")

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

@app.get("/")
async def root():
    return {"message": "Welcome to the Health Metrics API"}

@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": exc.detail},
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
