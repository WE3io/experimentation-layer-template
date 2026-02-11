from fastapi.testclient import TestClient
from datetime import datetime
from main import app

client = TestClient(app)

def test_log_single_event():
    payload = {
        "event_type": "plan_generated",
        "unit_type": "user",
        "unit_id": "user-123",
        "experiments": [
            {
                "experiment_id": "exp-1",
                "variant_id": "var-1"
            }
        ],
        "metrics": {"latency_ms": 450},
        "timestamp": "2025-01-01T10:00:00Z"
    }
    response = client.post("/api/v1/events", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert "event_id" in data
    assert data["status"] == "accepted"

def test_log_event_invalid_unit_type():
    payload = {
        "event_type": "test",
        "unit_type": "invalid",
        "unit_id": "123",
        "timestamp": "2025-01-01T10:00:00Z"
    }
    response = client.post("/api/v1/events", json=payload)
    assert response.status_code == 422 # Pydantic validation error

def test_log_batch_events():
    payload = {
        "events": [
            {
                "event_type": "e1",
                "unit_type": "user",
                "unit_id": "u1",
                "timestamp": "2025-01-01T10:00:00Z"
            },
            {
                "event_type": "e2",
                "unit_type": "household",
                "unit_id": "h1",
                "timestamp": "2025-01-01T10:01:00Z"
            }
        ]
    }
    response = client.post("/api/v1/events/batch", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["accepted"] == 2
    assert len(data["event_ids"]) == 2
