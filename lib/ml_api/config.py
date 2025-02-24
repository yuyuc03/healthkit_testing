import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_PATH = os.path.join(BASE_DIR, 'ml_models', 'health_model.pkl')

os.makedirs(os.path.join(BASE_DIR, 'ml_models'), exist_ok=True)