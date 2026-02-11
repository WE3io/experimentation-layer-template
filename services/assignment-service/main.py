import hashlib
from typing import List, Optional, Dict, Any
from fastapi import FastAPI, Header, HTTPException, Body
from pydantic import BaseModel, Field

app = FastAPI(title="Assignment Service API", version="1.0.0")

# --- Models ---

class AssignmentRequest(BaseModel):
    unit_type: str = Field(..., description="Type of unit: user, household, session")
    unit_id: str = Field(..., description="Unique identifier for the unit")
    context: Optional[Dict[str, Any]] = Field(default_factory=dict)
    requested_experiments: List[str] = Field(..., description="List of experiment names")

class VariantConfig(BaseModel):
    policy_version_id: Optional[str] = None
    execution_strategy: Optional[str] = None
    params: Dict[str, Any] = Field(default_factory=dict)

class Assignment(BaseModel):
    experiment_id: str
    experiment_name: str
    variant_id: str
    variant_name: str
    config: Dict[str, Any]

class SkippedExperiment(BaseModel):
    experiment_name: str
    reason: str

class AssignmentResponse(BaseModel):
    assignments: List[Assignment]
    skipped_experiments: List[SkippedExperiment]

# --- Logic ---

def get_bucket(experiment_name: str, unit_id: str) -> int:
    """Deterministic hashing for assignment bucketing (0-9999)."""
    # hash(experiment_name + ":" + unit_id)
    key = f"{experiment_name}:{unit_id}".encode()
    hash_hex = hashlib.md5(key).hexdigest()
    # bucket = unit_hash mod 10000
    return int(hash_hex, 16) % 10000

def mock_assignment(experiment_name: str, unit_id: str) -> Assignment:
    """Mock assignment logic for the walking skeleton."""
    bucket = get_bucket(experiment_name, unit_id)
    
    # Simple split: 50/50
    if bucket < 5000:
        variant_name = "control"
        variant_id = "00000000-0000-0000-0000-000000000001"
    else:
        variant_name = "treatment"
        variant_id = "00000000-0000-0000-0000-000000000002"
        
    return Assignment(
        experiment_id=f"exp-id-{experiment_name}",
        experiment_name=experiment_name,
        variant_id=variant_id,
        variant_name=variant_name,
        config={
            "execution_strategy": "mlflow_model",
            "mlflow_model": {
                "policy_version_id": "policy-v1",
                "model_name": "planner_model"
            },
            "params": {"temperature": 0.7}
        }
    )

# --- Endpoints ---

@app.post("/api/v1/assignments", response_model=AssignmentResponse)
async def get_assignments(
    request: AssignmentRequest,
    authorization: str = Header(None)
):
    # Minimal auth placeholder
    if not authorization or not authorization.startswith("Bearer "):
         # In a real app, we'd validate the token
         pass

    assignments = []
    skipped = []
    
    for exp_name in request.requested_experiments:
        # Mocking active check - everything is active in this skeleton
        if exp_name == "invalid_exp":
            skipped.append(SkippedExperiment(experiment_name=exp_name, reason="not_found"))
            continue
            
        assignments.append(mock_assignment(exp_name, request.unit_id))
        
    return AssignmentResponse(
        assignments=assignments,
        skipped_experiments=skipped
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
