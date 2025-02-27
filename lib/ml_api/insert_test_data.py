from motor.motor_asyncio import AsyncIOMotorClient
import asyncio
from datetime import datetime
import random

async def insert_test_data():

    client = AsyncIOMotorClient("mongodb://localhost:27017")
    db = client["health_predictions"]
    
    user_ids = ["user1", "user2", "user3", "user4", "user5"]
    
    for user_id in user_ids:
        health_data = {
            "user_id": user_id,
            "timestamp": datetime.now().isoformat(),
            "age": random.randint(30, 70),
            "gender": random.randint(1, 2),
            "height": random.uniform(150, 190),
            "weight": random.uniform(50, 100),
            "bmi": random.uniform(18, 35),
            "ap_hi": random.randint(100, 160),
            "ap_lo": random.randint(60, 100),
            "cholesterol": random.randint(1, 3),
            "gluc": random.randint(1, 3),
            "smoke": random.randint(0, 1),
            "alco": random.randint(0, 1),
            "active": random.randint(0, 1)
        }
        
        await db.health_data.insert_one(health_data)
        print(f"Inserted test data for {user_id}")
    
    client.close()

if __name__ == "__main__":
    asyncio.run(insert_test_data())
