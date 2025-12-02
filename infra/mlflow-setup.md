# MLflow Setup Guide

**Purpose**  
This document provides instructions for deploying and configuring MLflow for the experimentation system.

---

## Start Here If…

- **Deploying MLflow** → Follow sections 2-4
- **Configuring clients** → Focus on section 5
- **Understanding MLflow** → Go to [../docs/mlflow-guide.md](../docs/mlflow-guide.md)

---

## 1. MLflow Components

| Component | Purpose |
|-----------|---------|
| Tracking Server | Logs params, metrics, artefacts |
| Model Registry | Stores versioned models |
| Artefact Store | Persists model files (S3/MinIO) |
| Backend Store | Metadata database (PostgreSQL) |

---

## 2. Infrastructure Requirements

### 2.1 Minimum Resources

| Component | CPU | Memory | Storage |
|-----------|-----|--------|---------|
| MLflow Server | 2 cores | 4GB | 10GB |
| PostgreSQL | 2 cores | 4GB | 50GB |
| MinIO/S3 | 2 cores | 4GB | 500GB+ |

### 2.2 Network Requirements

| Port | Service | Access |
|------|---------|--------|
| 5000 | MLflow UI/API | Internal |
| 5432 | PostgreSQL | Internal |
| 9000 | MinIO API | Internal |
| 9001 | MinIO Console | Internal |

---

## 3. Deployment (Docker Compose)

### 3.1 Docker Compose Template

```yaml
# TODO: Replace with actual deployment configuration

version: '3.8'

services:
  mlflow:
    image: ghcr.io/mlflow/mlflow:v2.9.0
    ports:
      - "5000:5000"
    environment:
      - MLFLOW_BACKEND_STORE_URI=postgresql://mlflow:password@postgres:5432/mlflow
      - MLFLOW_DEFAULT_ARTIFACT_ROOT=s3://mlflow-artefacts/
      - AWS_ACCESS_KEY_ID=${MINIO_ACCESS_KEY}
      - AWS_SECRET_ACCESS_KEY=${MINIO_SECRET_KEY}
      - MLFLOW_S3_ENDPOINT_URL=http://minio:9000
    command: >
      mlflow server
      --host 0.0.0.0
      --port 5000
      --backend-store-uri postgresql://mlflow:password@postgres:5432/mlflow
      --default-artifact-root s3://mlflow-artefacts/
    depends_on:
      - postgres
      - minio

  postgres:
    image: postgres:15
    environment:
      - POSTGRES_USER=mlflow
      - POSTGRES_PASSWORD=password
      - POSTGRES_DB=mlflow
    volumes:
      - mlflow_postgres:/var/lib/postgresql/data

  minio:
    image: minio/minio:latest
    ports:
      - "9000:9000"
      - "9001:9001"
    environment:
      - MINIO_ROOT_USER=${MINIO_ACCESS_KEY}
      - MINIO_ROOT_PASSWORD=${MINIO_SECRET_KEY}
    volumes:
      - mlflow_minio:/data
    command: server /data --console-address ":9001"

  # Create bucket on startup
  minio-init:
    image: minio/mc:latest
    depends_on:
      - minio
    entrypoint: >
      /bin/sh -c "
      sleep 5;
      mc alias set myminio http://minio:9000 ${MINIO_ACCESS_KEY} ${MINIO_SECRET_KEY};
      mc mb myminio/mlflow-artefacts --ignore-existing;
      exit 0;
      "

volumes:
  mlflow_postgres:
  mlflow_minio:
```

### 3.2 Environment Variables

```bash
# .env file
MINIO_ACCESS_KEY=minioadmin
MINIO_SECRET_KEY=minioadmin123
```

### 3.3 Deployment Commands

```bash
# Start services
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f mlflow

# Stop services
docker-compose down
```

---

## 4. Kubernetes Deployment (Helm)

### 4.1 Helm Values Template

```yaml
# TODO: Customise for your cluster

# values.yaml
mlflow:
  replicaCount: 2
  
  image:
    repository: ghcr.io/mlflow/mlflow
    tag: v2.9.0
  
  service:
    type: ClusterIP
    port: 5000
  
  ingress:
    enabled: true
    hosts:
      - host: mlflow.internal.example.com
        paths:
          - path: /
            pathType: Prefix
  
  env:
    - name: MLFLOW_BACKEND_STORE_URI
      valueFrom:
        secretKeyRef:
          name: mlflow-secrets
          key: backend-store-uri
    - name: MLFLOW_DEFAULT_ARTIFACT_ROOT
      value: "s3://mlflow-artefacts/"
    - name: AWS_ACCESS_KEY_ID
      valueFrom:
        secretKeyRef:
          name: mlflow-secrets
          key: aws-access-key
    - name: AWS_SECRET_ACCESS_KEY
      valueFrom:
        secretKeyRef:
          name: mlflow-secrets
          key: aws-secret-key
    - name: MLFLOW_S3_ENDPOINT_URL
      value: "http://minio.storage.svc.cluster.local:9000"

postgresql:
  enabled: true
  auth:
    database: mlflow
    username: mlflow
    password: changeme
```

---

## 5. Client Configuration

### 5.1 Environment Variables

Set in training environments:

```bash
# MLflow tracking server
export MLFLOW_TRACKING_URI="http://mlflow.internal:5000"

# S3/MinIO for artefacts
export MLFLOW_S3_ENDPOINT_URL="http://minio.internal:9000"
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
```

### 5.2 Python Configuration

```python
# TODO: Replace with actual configuration

import mlflow

# Set tracking URI
mlflow.set_tracking_uri("http://mlflow.internal:5000")

# Verify connection
print(mlflow.get_tracking_uri())

# List experiments
experiments = mlflow.search_experiments()
for exp in experiments:
    print(f"Experiment: {exp.name}")
```

---

## 6. Security Configuration

### 6.1 Authentication (TODO)

MLflow does not have built-in authentication. Options:

1. **Reverse Proxy** (Recommended)
   - Use nginx/traefik with basic auth or OAuth

2. **MLflow Auth Plugin**
   - Use community plugins for auth

3. **Network Isolation**
   - Restrict access to internal network only

### 6.2 Example Nginx Config

```nginx
# TODO: Implement authentication

server {
    listen 443 ssl;
    server_name mlflow.example.com;
    
    ssl_certificate /etc/ssl/certs/mlflow.crt;
    ssl_certificate_key /etc/ssl/private/mlflow.key;
    
    location / {
        auth_basic "MLflow";
        auth_basic_user_file /etc/nginx/.htpasswd;
        
        proxy_pass http://mlflow:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

---

## 7. Backup & Recovery

### 7.1 Database Backup

```bash
# Backup PostgreSQL
pg_dump -h postgres -U mlflow mlflow > mlflow_backup.sql

# Restore
psql -h postgres -U mlflow mlflow < mlflow_backup.sql
```

### 7.2 Artefact Backup

```bash
# Sync to backup location
aws s3 sync s3://mlflow-artefacts s3://mlflow-artefacts-backup \
    --endpoint-url http://minio:9000

# Or use MinIO client
mc mirror myminio/mlflow-artefacts backup/mlflow-artefacts
```

---

## 8. Monitoring

### 8.1 Health Check

```bash
# Check MLflow server health
curl http://mlflow:5000/health

# Expected response
# {"status": "OK"}
```

### 8.2 Metrics (Prometheus)

```yaml
# TODO: Configure Prometheus scraping

# prometheus.yml
scrape_configs:
  - job_name: 'mlflow'
    static_configs:
      - targets: ['mlflow:5000']
    metrics_path: /metrics
```

---

## 9. Troubleshooting

### 9.1 Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Cannot connect | Network/firewall | Check ports, DNS |
| Artefact upload fails | S3 credentials | Verify AWS env vars |
| Slow queries | Large model registry | Add database indexes |
| Out of storage | Too many artefacts | Implement retention policy |

### 9.2 Debug Commands

```bash
# Test S3 connectivity
aws s3 ls s3://mlflow-artefacts --endpoint-url http://minio:9000

# Test PostgreSQL connectivity
psql -h postgres -U mlflow -d mlflow -c "SELECT 1"

# Check MLflow logs
docker logs mlflow --tail 100
```

---

## 10. TODO: Implementation Checklist

- [ ] Deploy PostgreSQL for backend store
- [ ] Deploy MinIO/S3 for artefact store
- [ ] Deploy MLflow server
- [ ] Configure authentication
- [ ] Set up TLS/SSL
- [ ] Configure backups
- [ ] Set up monitoring
- [ ] Document internal URLs

---

## Related Documentation

| Document | Purpose |
|----------|---------|
| [../docs/mlflow-guide.md](../docs/mlflow-guide.md) | MLflow usage |
| [environments.md](environments.md) | Environment setup |
| [../docs/training-workflow.md](../docs/training-workflow.md) | Training process |

