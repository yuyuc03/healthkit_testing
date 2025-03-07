from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from motor.motor_asyncio import AsyncIOMotorClient
from datetime import datetime
import joblib
import os
import numpy as np
import certifi
from openai import OpenAI


app = FastAPI()

client = AsyncIOMotorClient(
    "mongodb+srv://yuyucheng2003:2yjbDeyUfi2GF8KI@healthmetrics.z6rit.mongodb.net/?retryWrites=true&w=majority&appName=HealthMetrics",
    tlsCAFile=certifi.where()
)
health_metrics_db = client["test"]

prediction_collection = health_metrics_db["prediction"]
ml_model_data_collection = health_metrics_db["ml_model_data"]
gpt_data_collection = health_metrics_db["gpt_data"]

model_path = os.path.join('ml_models', 'health_model.joblib')
model_data = joblib.load(model_path)
svm_model = model_data['model']
scaler = model_data['scaler']
feature_names = model_data['feature_name']

openai_client = OpenAI(api_key = "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")

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

class GPTRequest(BaseModel):
    user_id: str

class GPTResponse(BaseModel):
    suggestion: str

class UserProfileUpdate(BaseModel):
    user_id: str
    age: float
    gender: int
    height: float
    weight: float
    smoke: int
    alco: int
    active: int

@app.post("/predict/", response_model = PredictionOutput)
async def predict():
    try:
        latest_data = await ml_model_data_collection.find_one(sort=[("timestamp", -1)])
        print(f"Latest data: {latest_data}")

        if not latest_data:
            raise HTTPException(status_code=404, detail="Sorry, we didn't found any data from ml_model_data collection")

        user_id = latest_data.get("user_id")
        if not user_id:
            raise HTTPException(status_code=422, detail="Sorry, we didn't found any User ID in the latest data")

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
            prediction = float(svm_model.predict(scaled_input)[0])
            probabilities = svm_model.predict_proba(scaled_input)[0]
            risk_probability = probabilities[1]  

            print(f"Prediction Result: {prediction}, Probability of getting heart disease: {risk_probability}")
        except Exception as model_error:
            print(f"The prediction process was failed: {str(model_error)}")
            raise HTTPException(status_code=500, detail=f"Model prediction error: {str(model_error)}")

        
        prediction_store = {
            "user_id": user_id,
            "timestamp": latest_data.get("timestamp"),
            "age": latest_data.get("age"),
            "gender": latest_data.get("gender"),
            "height": latest_data.get("height"),
            "weight": latest_data.get("weight"),
            "bmi": latest_data.get("bmi"),
            "ap_hi": latest_data.get("ap_hi"),
            "ap_lo": latest_data.get("ap_lo"),
            "cholesterol": latest_data.get("cholesterol"),
            "gluc": latest_data.get("gluc"),
            "smoke": latest_data.get("smoke"),
            "alco": latest_data.get("alco"),
            "active": latest_data.get("active"),
            "prediction": float(prediction),
            "risk_probability": float(risk_probability),
        }

        try:
            await prediction_collection.insert_one(prediction_store)
            print("We have successfully save the prediction result together with some users' data")
        except Exception as db_error:
            print(f"Sorry, we can't store the result: {str(db_error)}")
            raise HTTPException(status_code=500, detail=f"Database error: {str(db_error)}")

        return PredictionOutput(prediction=float(prediction), risk_probability=float(risk_probability))
    except Exception as e:
        print(f"Unexpected error in predict endpoint: {str(e)}")
        raise HTTPException(status_code=500, detail=f"An unexpected error occurred: {str(e)}")

@app.post("/generate_suggestion/", response_model = GPTResponse)
async def generate_suggestion(request: GPTRequest):
    print(f"Received request for user_id: {request.user_id}")
    
    prediction_data = await prediction_collection.find_one({"user_id": request.user_id})
    print(f"Prediction data: {prediction_data}")

    if not prediction_data:
        raise HTTPException(status_code = 422, detail = "Prediction data not found for $user_id")
        

    user_data = await gpt_data_collection.find_one({"user_id": request.user_id})

    if not user_data:
        raise HTTPException(status_code=404, detail="User' extra data not found")
        
    prompt = f"""You are a highly experienced health advisor AI. Based on the following patient information, provide actionable recommendations.
        Users' Information:
        - Age: {prediction_data['age']}
        - Gender: {'Male' if prediction_data['gender'] == 1 else 'Female'}
        - Height: {prediction_data['height']} cm
        - Weight: {prediction_data['weight']} kg
        - BMI: {prediction_data['bmi']}
        - Blood Pressure: {prediction_data['ap_hi']}/{prediction_data['ap_lo']} mmHg
        - Cholesterol Level: {prediction_data['cholesterol']}
        - Glucose Level: {prediction_data['gluc']}
        - Smoking Habit: {'Yes' if prediction_data['smoke'] == 1 else 'No'}
        - Alcohol Intake: {'Yes' if prediction_data['alco'] == 1 else 'No'}
        - Activity Level: {'Active' if prediction_data['active'] == 1 else 'Inactive'}
        - Ethnicity: {user_data['ethnicity']}
        - Country of Origin: {user_data['country_of_origin']}
       - Dietary Habits: {user_data['dietary_habits']}
       - Current Medications: {user_data['current_medications']}

       Instructions:
       Provide three specific lifestyle recommendations tailored to this patient's cultural background.
       Format your response as a list of recommendations with explanations.
       """
        
    try:
        response = openai_client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[
                {"role": "system", "content": "You are a helpful assistant."},
                {"role": "user", "content": prompt}
            ],
            max_tokens = 250
        )

        suggestion = response.choices[0].message.content.strip()

        await prediction_collection.update_one(
            {"user_id": request.user_id},
            {"$set": {"gpt_suggestion": suggestion}}
        )

        return GPTResponse(suggestion = suggestion)

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error calling GPT API: {str(e)}")

@app.post("/update_user_data/")
async def update_user_data(data: UserProfileUpdate):
    try:
        # Calculate BMI
        bmi = data.weight / ((data.height / 100) ** 2)
        
        # Create update document
        update_data = {
            "timestamp": datetime.now().isoformat(),
            "user_id": data.user_id,
            "age": data.age,
            "gender": data.gender,
            "height": data.height,
            "weight": data.weight,
            "bmi": round(bmi, 2),
            "smoke": data.smoke,
            "alco": data.alco,
            "active": data.active
        }
        
        # Update or insert into ml_model_data collection
        result = await ml_model_data_collection.update_one(
            {"user_id": data.user_id},
            {"$set": update_data},
            upsert=True
        )
        
        return {"message": "User data updated successfully", "modified_count": result.modified_count}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error updating user data: {str(e)}")

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
