# Pipelines

**Purpose**  
This directory contains specifications for offline data pipelines.

---

## Start Here If…

- **Understanding pipelines** → Read this document
- **Generating training data** → Go to [training-data.md](training-data.md)
- **Aggregating metrics** → Go to [metrics-aggregation.md](metrics-aggregation.md)
- **Evaluating models** → Go to [offline-replay.md](offline-replay.md)

---

## Pipeline Overview

| Pipeline | Schedule | Purpose |
|----------|----------|---------|
| Training Data | Daily | Generate training datasets from events |
| Metrics Aggregation | Hourly | Compute experiment metrics |
| Offline Replay | On-demand | Evaluate candidate models |

---

## Orchestration

Pipelines are designed to run on:
- **Airflow** (recommended)
- **Prefect**
- **Dagster**
- **Cron** (simple deployments)

---

## Pipeline Files

| File | Purpose |
|------|---------|
| [training-data.md](training-data.md) | Training dataset generation |
| [metrics-aggregation.md](metrics-aggregation.md) | Experiment metrics |
| [offline-replay.md](offline-replay.md) | Model evaluation |

---

## TODO: Implementation Notes

- [ ] Choose orchestrator (Airflow/Prefect)
- [ ] Implement pipeline scripts
- [ ] Set up scheduling
- [ ] Configure alerting

