import os
from fastapi import FastAPI

app = FastAPI()

def get_app_version():
    version = os.getenv("APP_VERSION", "UNKNOWN")
    if version != "UNKNOWN":
        return version[:8]
    return version

@app.get("/")
async def say_hello(name: str = "World"):
    return f"Hello {name}"

@app.get("/api/system/about")
async def about():
    return {"version": get_app_version()}
