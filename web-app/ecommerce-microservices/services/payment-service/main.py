import os
import threading
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
from database import engine, Base
from routes.payment import router as payment_router
from grpc_server import serve

load_dotenv()

# Create all database tables
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Payment Service",
    description="Handles payment processing for the e-commerce platform",
    version="1.0.0",
)

@app.on_event("startup")
def startup_event():
    # Run the gRPC server in a background daemon thread
    grpc_port = int(os.getenv("GRPC_PORT", 50051))
    grpc_thread = threading.Thread(target=serve, args=(grpc_port,), daemon=True)
    grpc_thread.start()

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Routes
app.include_router(payment_router)


@app.get("/health")
def health_check():
    return {"service": "payment-service", "status": "ok"}


if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 3004))
    uvicorn.run("main:app", host="0.0.0.0", port=port, reload=True)
