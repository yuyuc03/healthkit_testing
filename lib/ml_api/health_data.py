from pydantic import BaseModel, Field

class HealthDataInput(BaseModel):
    age: float
    gender: int = Field(..., ge=1, le=2)
    height: float
    weight: float
    bmi: float
    ap_hi: float
    ap_lo: float
    cholesterol: int = Field(..., ge=1, le=3)
    gluc: int = Field(..., ge=1, le=3)
    smoke: int = Field(..., ge=0, le=1)
    alco: int = Field(..., ge=0, le=1)
    active: int = Field(..., ge=0, le=1)

class PredictionResponse(BaseModel):
    cardio_risk: int
    probability: float