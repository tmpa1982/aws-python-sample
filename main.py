from fastapi import FastAPI

app = FastAPI()

@app.get("/")
async def say_hello(name: str = "World"):
    return f"Hello {name}"
