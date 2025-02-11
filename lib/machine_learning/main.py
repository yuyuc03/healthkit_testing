# Bring in lightweight dependencies
from fastapi import FastAPI

# Cerate instance for app
app = FastAPI()

# Create decorator to tell our API what the route is going to be
@app.get('/') # Change / to post later on

# Define what actually got call when we go to this route
async def scoring_endpoint():
    return {"hello":"world"}