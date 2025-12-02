# Metabase Setup Guide

**Purpose**  
This document provides instructions for deploying and configuring Metabase for experiment analytics.

---

## Start Here If…

- **Deploying Metabase** → Follow sections 2-3
- **Connecting to data** → Focus on section 4
- **Building dashboards** → Go to [../analytics/metabase-models.md](../analytics/metabase-models.md)

---

## 1. Overview

Metabase provides:
- Interactive dashboards
- SQL query interface
- Scheduled reports
- Embeddable visualisations

---

## 2. Deployment (Docker)

### 2.1 Docker Compose

```yaml
# TODO: Customise for your environment

version: '3.8'

services:
  metabase:
    image: metabase/metabase:latest
    ports:
      - "3000:3000"
    environment:
      - MB_DB_TYPE=postgres
      - MB_DB_DBNAME=metabase
      - MB_DB_PORT=5432
      - MB_DB_USER=metabase
      - MB_DB_PASS=password
      - MB_DB_HOST=postgres
    depends_on:
      - postgres

  postgres:
    image: postgres:15
    environment:
      - POSTGRES_USER=metabase
      - POSTGRES_PASSWORD=password
      - POSTGRES_DB=metabase
    volumes:
      - metabase_postgres:/var/lib/postgresql/data

volumes:
  metabase_postgres:
```

### 2.2 Start Metabase

```bash
docker-compose up -d
# Access at http://localhost:3000
```

---

## 3. Initial Configuration

### 3.1 Setup Wizard

1. Navigate to http://localhost:3000
2. Create admin account
3. Skip sample database
4. Add experimentation database connection

### 3.2 Database Connection

```
Database Type: PostgreSQL
Name: Experimentation DB
Host: <postgres-host>
Port: 5432
Database: <your-database>
Username: <read-only-user>
Password: <password>
Schema: exp
```

---

## 4. Data Models

### 4.1 Required Tables

Configure these tables in Metabase:

| Table | Purpose |
|-------|---------|
| `exp.experiments` | Experiment definitions |
| `exp.variants` | Variant configurations |
| `exp.events` | Raw event logs |
| `exp.metric_aggregates` | Aggregated metrics |
| `exp.policy_versions` | Model versions |

### 4.2 Required Views

| View | Purpose |
|------|---------|
| `exp.v_experiment_metrics` | Dashboard metrics |
| `exp.v_active_experiments` | Active experiments |
| `exp.v_policy_versions` | Policy details |

---

## 5. User Management

### 5.1 Groups

| Group | Access |
|-------|--------|
| Admins | Full access |
| Data Analysts | Query + dashboard access |
| Developers | Read-only dashboards |

### 5.2 Permissions

```
# TODO: Configure in Metabase admin

exp schema:
  - Admins: Full access
  - Data Analysts: Query builder + native queries
  - Developers: View data only
```

---

## 6. Scheduled Reports

### 6.1 Daily Experiment Summary

- Send: Daily at 9am
- Recipients: Team email list
- Content: Active experiment metrics

### 6.2 Weekly Model Performance

- Send: Monday at 10am
- Recipients: ML team
- Content: Model comparison charts

---

## 7. TODO: Implementation Checklist

- [ ] Deploy Metabase
- [ ] Connect to experimentation database
- [ ] Configure user groups
- [ ] Set up required dashboards (see analytics/metabase-models.md)
- [ ] Configure scheduled reports
- [ ] Set up alerts

---

## Related Documentation

| Document | Purpose |
|----------|---------|
| [../analytics/metabase-models.md](../analytics/metabase-models.md) | Dashboard specifications |
| [../analytics/example-queries.sql](../analytics/example-queries.sql) | SQL examples |
| [postgres-schema-overview.sql](postgres-schema-overview.sql) | Database schema |

