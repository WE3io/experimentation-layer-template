# Infrastructure: Local Development Stack

## Outcome

A `docker-compose.yml` file and accompanying `.env.example` in the `infra/` directory that allows a developer to start the core platform stack (PostgreSQL, MLflow, Redis, Metabase) locally with a single command. The services are pre-configured to communicate with each other.

## Constraints & References

- **Core Stack:** Defined in `onboarding-spec.md` (Core Stack section).
- **Database Schema:** Must use `infra/postgres-schema-overview.sql` for initialization.
- **MLflow Backend:** Must be configured to use the PostgreSQL container as its backend store.
- **Standard Images:** Use official Docker Hub images where possible (e.g., `postgres:15`, `redis:7`, `metabase/metabase`).
- **Network:** All services should reside on a shared internal Docker network.

## Acceptance Checks

- [ ] `infra/docker-compose.yml` exists and includes `postgres`, `mlflow`, `redis`, and `metabase`.
- [ ] `infra/.env.example` contains all necessary environment variables (DB credentials, ports, etc.).
- [ ] Running `docker-compose up` initializes the `exp` schema in PostgreSQL automatically.
- [ ] MLflow UI is accessible at `localhost:5000` and stores experiment metadata in Postgres.
- [ ] Metabase is accessible at `localhost:3000` and can connect to the Postgres database.
- [ ] Redis is accessible by other containers (e.g., for future session management).

## Explicit Non-Goals

- Implementation of production-grade infrastructure (K8s, Terraform).
- Setting up persistent volume backups or cloud storage integration (S3/MinIO) in this item.
- Populating the database with large-scale sample data.
