
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base
from sqlalchemy.orm import sessionmaker

SQLALCHEMY_DATABASE_URL = "sqlite:////Users/yuyu/Library/Developer/CoreSimulator/Devices/B5D0593B-15E9-4CBA-8109-7C7476E5F0BD/data/Containers/Data/Application/0E542441-182F-4935-AC39-32766E7E7B4C/Documents/health_metrics.db"  

# Initialized a connection to the SQLite Database
engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
)

# Test the connection
with engine.connect() as connection:
    print("Connection successful")

# Creating a database session object which can use to interact with database (such as querying, inserting, or updating data)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

