import uuid
from datetime import datetime
from typing import List, Optional, Dict, Any
from fastapi import FastAPI, Header, HTTPException, Body, Response, status
from pydantic import BaseModel, Field, validator

app = FastAPI(title="Event Ingestion Service API", version="1.0.0")

# --- Models ---

class ExperimentContext(BaseModel):
    experiment_id: str
    variant_id: str

class Event(BaseModel):
    event_type: str
    unit_type: str = Field(..., pattern="^(user|household|session)$")
    unit_id: str
    experiments: List[ExperimentContext] = Field(default_factory=list)
    context: Dict[str, Any] = Field(default_factory=dict)
    metrics: Dict[str, Any] = Field(default_factory=dict)
    payload: Optional[Dict[str, Any]] = None
    timestamp: datetime

class BatchRequest(BaseModel):
    events: List[Event]

class EventResponse(BaseModel):
    event_id: str
    status: str

class BatchResponse(BaseModel):
    accepted: int
    rejected: int
    event_ids: List[str]
    errors: Optional[List[Dict[str, Any]]] = None

# --- Endpoints ---

@app.post("/api/v1/events", response_model=EventResponse)
async def log_event(
    event: Event,
    authorization: str = Header(None)
):
    # Minimal auth placeholder
    if not authorization or not authorization.startswith("Bearer "):
        pass

    # In a real app, we'd write to Postgres/S3 here
    event_id = str(uuid.uuid4())
    
    return EventResponse(
        event_id=event_id,
        status="accepted"
    )

@app.post("/api/v1/events/batch", response_model=BatchResponse)
async def log_batch_events(
    request: BatchRequest,
    response: Response,
    authorization: str = Header(None)
):
    accepted = 0
    rejected = 0
    event_ids = []
    errors = []
    
    for idx, event in enumerate(request.events):
        try:
            # Simulate processing
            event_id = str(uuid.uuid4())
            event_ids.append(event_id)
            accepted += 1
        except Exception as e:
            rejected += 1
            errors.append({"index": idx, "error": str(e)})
            
    if rejected > 0:
        response.status_code = status.HTTP_207_MULTI_STATUS
        
    return BatchResponse(
        accepted=accepted,
        rejected=rejected,
        event_ids=event_ids,
        errors=errors if errors else None
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8002)
