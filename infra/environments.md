# Environments Guide

**Purpose**  
This document describes the different environments and their configurations.

---

## Start Here If…

- **Setting up local dev** → Section 2
- **Understanding staging/prod** → Section 3-4
- **Configuring services** → Section 5

---

## 1. Environment Overview

| Environment | Purpose | Data |
|-------------|---------|------|
| Local | Development | Mock/sample |
| Staging | Integration testing | Anonymised production |
| Production | Live traffic | Real data |

---

## 2. Local Development

### 2.1 Required Services

```bash
# Docker Compose for local development
docker-compose -f docker-compose.local.yml up -d
```

Services:
- PostgreSQL (port 5432)
- MLflow (port 5000)
- MinIO (port 9000)
- Redis (port 6379)

### 2.2 Environment Variables

```bash
# .env.local

# Database
DATABASE_URL=postgresql://dev:dev@localhost:5432/experimentation

# MLflow
MLFLOW_TRACKING_URI=http://localhost:5000
MLFLOW_S3_ENDPOINT_URL=http://localhost:9000
AWS_ACCESS_KEY_ID=minioadmin
AWS_SECRET_ACCESS_KEY=minioadmin

# Redis
REDIS_URL=redis://localhost:6379

# Services
ASSIGNMENT_SERVICE_URL=http://localhost:8001
EVENT_SERVICE_URL=http://localhost:8002
```

---

## 3. Staging Environment

### 3.1 Configuration

```bash
# .env.staging

# Database
DATABASE_URL=postgresql://app:****@staging-db:5432/experimentation

# MLflow
MLFLOW_TRACKING_URI=http://mlflow.staging.internal:5000
MLFLOW_S3_ENDPOINT_URL=http://minio.staging.internal:9000

# Services
ASSIGNMENT_SERVICE_URL=http://assignment.staging.internal:8001
EVENT_SERVICE_URL=http://events.staging.internal:8002
```

### 3.2 Data Policy

- Anonymised production data
- Refreshed weekly
- No PII

---

## 4. Production Environment

### 4.1 Configuration

```bash
# .env.production

# Database (read replicas for analytics)
DATABASE_URL=postgresql://app:****@prod-db:5432/experimentation
DATABASE_REPLICA_URL=postgresql://readonly:****@prod-replica:5432/experimentation

# MLflow
MLFLOW_TRACKING_URI=http://mlflow.prod.internal:5000

# Services
ASSIGNMENT_SERVICE_URL=http://assignment.prod.internal:8001
EVENT_SERVICE_URL=http://events.prod.internal:8002
```

### 4.2 Security

- Secrets in vault/secrets manager
- TLS everywhere
- Network segmentation

---

## 5. Service URLs

### 5.1 Internal Services

| Service | Local | Staging | Production |
|---------|-------|---------|------------|
| Assignment | localhost:8001 | assignment.staging | assignment.prod |
| Events | localhost:8002 | events.staging | events.prod |
| MLflow | localhost:5000 | mlflow.staging | mlflow.prod |
| Metabase | localhost:3000 | metabase.staging | metabase.prod |

---

## 6. TODO: Implementation Checklist

- [ ] Create docker-compose.local.yml
- [ ] Set up staging environment
- [ ] Configure production infrastructure
- [ ] Set up secrets management
- [ ] Document network topology

---

## Related Documentation

| Document | Purpose |
|----------|---------|
| [mlflow-setup.md](mlflow-setup.md) | MLflow deployment |
| [metabase-setup.md](metabase-setup.md) | Metabase deployment |
| [postgres-schema-overview.sql](postgres-schema-overview.sql) | Database setup |

