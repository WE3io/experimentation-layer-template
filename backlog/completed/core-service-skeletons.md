# Implementation: Core Service Skeletons

## Outcome

Functional Python-based skeletons for the `assignment-service` and `event-ingestion-service` that implement the core platform logic and include unit tests. These services serve as "walking skeletons" that developers can run and extend.

## Constraints & References

- **Assignment Logic:** Must follow the deterministic hashing logic in `onboarding-spec.md` (Section 5).
- **EIS Responsibilities:** Must implement the validation logic described in `onboarding-spec.md` (Section 6).
- **API Specs:** Must align with `services/assignment-service/API_SPEC.md` and `services/event-ingestion-service/API_SPEC.md`.
- **Framework:** Prefer a lightweight framework like FastAPI or Flask.
- **Testing:** Must include unit tests using `pytest` or similar.

## Acceptance Checks

- [ ] `services/assignment-service/` contains a runnable Python application implementing `POST /assign`.
- [ ] `services/event-ingestion-service/` contains a runnable Python application implementing `POST /collect`.
- [ ] Assignment logic correctly implements `hash(experiment_id + ":" + unit_id) mod 10000`.
- [ ] Event ingestion service validates incoming event payloads against required fields.
- [ ] Unit tests exist for both services and can be run locally.
- [ ] A minimal `requirements.txt` or `pyproject.toml` is provided for each service.

## Explicit Non-Goals

- Implementing full database persistence (ORMs, connection pooling) beyond simple mock implementations or stubs.
- Implementation of Authentication or Authorization.
- Service containerization (covered in a separate infrastructure item).
