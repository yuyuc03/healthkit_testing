import sqlite3
from contextlib import contextmanager
from datetime import datetime
from .health_data import HealthDataInput
import os


DATABASE_URL = os.path.join(os.path.dirname(os.path.abspath(__file__)), "cardio_predictions.db")



def init_db():
    with get_db_connection() as conn:
        conn.execute('''
            CREATE TABLE IF NOT EXISTS predictions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                timestamp TEXT,
                ap_hi FLOAT,
                ap_lo FLOAT,
                cholesterol INTEGER,
                gluc INTEGER,
                active INTEGER,
                prediction INTEGER,
                probability FLOAT
            )
        ''')
        conn.commit()

@contextmanager
def get_db_connection():
    conn = sqlite3.connect(DATABASE_URL)
    try:
        yield conn
    finally:
        conn.close()

def save_prediction(data: HealthDataInput, prediction: int, probability: float):
    with get_db_connection() as conn:
        cursor = conn.cursor()
        cursor.execute('''
            INSERT INTO predictions 
            (timestamp, ap_hi, ap_lo, cholesterol, gluc, 
             active, prediction, probability)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            datetime.now().isoformat(),
            data.ap_hi,
            data.ap_lo,
            data.cholesterol,
            data.gluc,
            data.active,
            prediction,
            float(probability) if probability is not None else 0.0
        ))
        conn.commit()
