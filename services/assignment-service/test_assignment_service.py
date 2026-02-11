from fastapi.testclient import TestClient
from main import app, get_bucket

client = TestClient(app)

def test_get_bucket_deterministic():
    # Same inputs should result in same bucket
    bucket1 = get_bucket("test_exp", "user-123")
    bucket2 = get_bucket("test_exp", "user-123")
    assert bucket1 == bucket2
    assert 0 <= bucket1 < 10000

def test_get_bucket_distribution():
    # Different users should (ideally) have different buckets
    bucket1 = get_bucket("test_exp", "user-123")
    bucket2 = get_bucket("test_exp", "user-456")
    assert bucket1 != bucket2

def test_assignments_endpoint():
    payload = {
        "unit_type": "user",
        "unit_id": "user-123",
        "requested_experiments": ["planner_policy_exp"]
    }
    headers = {"Authorization": "Bearer test-token"}
    response = client.post("/api/v1/assignments", json=payload, headers=headers)
    
    assert response.status_code == 200
    data = response.json()
    assert "assignments" in data
    assert len(data["assignments"]) == 1
    assert data["assignments"][0]["experiment_name"] == "planner_policy_exp"
    assert "variant_name" in data["assignments"][0]
    assert "config" in data["assignments"][0]

def test_assignments_skipped():
    payload = {
        "unit_type": "user",
        "unit_id": "user-123",
        "requested_experiments": ["invalid_exp"]
    }
    response = client.post("/api/v1/assignments", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert len(data["skipped_experiments"]) == 1
    assert data["skipped_experiments"][0]["reason"] == "not_found"
