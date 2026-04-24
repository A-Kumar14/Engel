from fastapi import FastAPI

from app.api.routes import router
from app.db import Base, engine


Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Two Globes Backend",
    version="0.1.0",
    summary="API for entries, pointers, and weekly insights.",
)

app.include_router(router)
