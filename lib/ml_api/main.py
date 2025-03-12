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
from fastapi.middleware.cors import CORSMiddleware


app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

mongo_uri = os.environ.get("MONGO_URI", "mongodb+srv://yuyucheng2003:2yjbDeyUfi2GF8KI@healthmetrics.z6rit.mongodb.net/?retryWrites=true&w=majority&appName=HealthMetrics")
client = AsyncIOMotorClient(mongo_uri, tlsCAFile=certifi.where())

health_metrics_db = client["test"]

prediction_collection = health_metrics_db["prediction"]
ml_model_data_collection = health_metrics_db["ml_model_data"]
gpt_data_collection = health_metrics_db["gpt_data"]

model_path = os.path.join('ml_models', 'health_model.joblib')
model_data = joblib.load(model_path)
svm_model = model_data['model']
scaler = model_data['scaler']
feature_names = model_data['feature_name']

openai_api_key = os.environ.get("OPENAI_API_KEY", "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")
openai_client = OpenAI(api_key=openai_api_key)

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
        
    prompt = f"""You are a supportive health coach providing personalized advice. Based on this health profile:
            - Age: {prediction_data['age']}
            - Gender: {'Male' if prediction_data['gender'] == 1 else 'Female'}
            - Height: {prediction_data['height']} cm
            - Weight: {prediction_data['weight']} kg
            - BMI: {prediction_data['bmi']}
            - Blood Pressure: {prediction_data['ap_hi']}/{prediction_data['ap_lo']} mmHg
            - Cholesterol: {prediction_data['cholesterol']}
            - Glucose: {prediction_data['gluc']}
            - Smoking: {'Yes' if prediction_data['smoke'] == 1 else 'No'}
            - Alcohol: {'Yes' if prediction_data['alco'] == 1 else 'No'}
            - Activity: {'Active' if prediction_data['active'] == 1 else 'Inactive'}
            - Ethnicity: {user_data['ethnicity']}
            - Origin: {user_data['country_of_origin']}
            - Diet: {user_data['dietary_habits']}
            - Medications: {user_data['current_medications']}
            - Specific Cultural Identity: {user_data['cultural_identity']}

            Provide 3 specific, actionable health tips in a friendly tone. Each tip should:
            1. Be 1-2 sentences only
            2. Focus on one key health improvement
            3. Be culturally appropriate
            4. Consider their current health metrics
            5. Be practical for daily implementation

            Format as a brief intro followed by 3 numbered tips. Total response should be under 150 words.
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
        bmi = data.weight / ((data.height / 100) ** 2)
        
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


@app.post("/chat/")
async def chat_with_ai(request: Request):
    try:
        data = await request.json()
        user_id = data.get("user_id")
        message = data.get("message")
        
        if not user_id or not message:
            raise HTTPException(status_code=422, detail="Missing user_id or message")
        
        user_data = await gpt_data_collection.find_one({"user_id": user_id})
        prediction_data = await prediction_collection.find_one({"user_id": user_id})
        
        if not user_data or not prediction_data:
            prompt = f"You are a health assistant AI. The user asks: {message}"
        else:
            prompt = f"""You are a health assistant AI. Here's some context about the user:
            - Age: {prediction_data['age']}
            - Gender: {'Male' if prediction_data['gender'] == 1 else 'Female'}
            - Height: {prediction_data['height']} cm
            - Weight: {prediction_data['weight']} kg
            - BMI: {prediction_data['bmi']}
            - Blood Pressure: {prediction_data['ap_hi']}/{prediction_data['ap_lo']} mmHg
            - Cholesterol: {prediction_data['cholesterol']}
            - Glucose: {prediction_data['gluc']}
            - Smoking: {'Yes' if prediction_data['smoke'] == 1 else 'No'}
            - Alcohol: {'Yes' if prediction_data['alco'] == 1 else 'No'}
            - Activity: {'Active' if prediction_data['active'] == 1 else 'Inactive'}
            - Ethnicity: {user_data['ethnicity']}
            - Origin: {user_data['country_of_origin']}
            - Diet: {user_data['dietary_habits']}
            - Medications: {user_data['current_medications']}
            - Specific Cultural Identity: {user_data['cultural_identity']}
            - Health status: {'At risk of heart disease' if prediction_data.get('prediction') == 1 else 'Healthy'}
            
            The user asks: {message}
            
            Provide a helpful, accurate response based on medical knowledge. Keep your answer concise and don't always give the same response.
            """
        
        response = openai_client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[
                {"role": "system", "content": "You are a helpful health assistant."},
                {"role": "user", "content": prompt}
            ],
            max_tokens=150
        )
        
        ai_response = response.choices[0].message.content.strip()
        
        await health_metrics_db.chat_history.insert_one({
            "user_id": user_id,
            "timestamp": datetime.now().isoformat(),
            "user_message": message,
            "ai_response": ai_response
        })
        
        return {"response": ai_response}
    
    except Exception as e:
        print(f"Error in chat endpoint: {str(e)}")
        raise HTTPException(status_code=500, detail=f"An error occurred: {str(e)}")

