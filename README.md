# Experimentation & Model Lifecycle Platform

**Purpose**  
This repository provides the complete foundation for experimentation, model training, fine-tuning, evaluation, and deployment. It is designed for senior developers who may not have prior MLOps experience.

---

## Quick Navigation

### Start Here If…

| Your Goal | Entry Point |
|-----------|-------------|
| Learn the full system end-to-end | [Sequential Learning Path](#sequential-learning-path) |
| Work on experiments only | [Experiment Route](docs/routes/experiment-route.md) |
| Work on event logging | [Event Logging Route](docs/routes/event-logging-route.md) |
| Work on training/fine-tuning | [Training Route](docs/routes/training-route.md) |
| Work on offline evaluation | [Offline Evaluation Route](docs/routes/offline-evaluation-route.md) |
| Work on model promotion | [Model Promotion Route](docs/routes/model-promotion-route.md) |
| Work on analytics/dashboards | [Analytics Route](docs/routes/analytics-route.md) |

---

## Sequential Learning Path

Follow this order for complete understanding:

1. [Architecture Overview](docs/architecture.md)
2. [Data Model](docs/data-model.md)
3. [Experiments](docs/experiments.md)
4. [Assignment Service](docs/assignment-service.md)
5. [Event Ingestion Service](docs/event-ingestion-service.md)
6. [MLflow Guide](docs/mlflow-guide.md)
7. [Training Workflow](docs/training-workflow.md)
8. [Offline Evaluation](docs/offline-evaluation.md)
9. [Model Promotion](docs/model-promotion.md)
10. [Metabase & Analytics](analytics/metabase-models.md)

---

## Repository Structure

```
/
├── README.md                          ← You are here
├── docs/                              ← Core documentation
│   ├── README.md                      ← Documentation index
│   ├── architecture.md                ← System architecture
│   ├── data-model.md                  ← PostgreSQL schema
│   ├── experiments.md                 ← Experiment concepts
│   ├── assignment-service.md          ← Assignment service overview
│   ├── event-ingestion-service.md     ← Event service overview
│   ├── mlflow-guide.md                ← MLflow usage
│   ├── training-workflow.md           ← Training process
│   ├── offline-evaluation.md          ← Offline replay evaluation
│   ├── model-promotion.md             ← Promotion lifecycle
│   ├── mlops-concepts.md              ← MLOps primer
│   └── routes/                        ← Parallel exploration routes
├── services/                          ← Service specifications
│   ├── assignment-service/
│   └── event-ingestion-service/
├── infra/                             ← Infrastructure setup
├── pipelines/                         ← Pipeline specifications
├── training/                          ← Training templates
├── datasets/                          ← Dataset conventions
├── analytics/                         ← Metabase & queries
└── config/                            ← Configuration examples
```

---

## Core Stack

| Component | Purpose |
|-----------|---------|
| PostgreSQL | Primary metadata store (experiments, events, policies) |
| MLflow | Model registry and experiment tracking |
| Metabase | Dashboards and experiment visualisation |
| Open-source LLMs | LLaMA, Mistral, Qwen, etc. |
| Object Storage | S3/MinIO for datasets and ML artefacts |
| Orchestrator | Airflow or Prefect |
| Task Queue | Redis/worker for async jobs |
| Docker | Containerisation |

---

## Getting Started

### For New Developers

1. Read [MLOps Concepts](docs/mlops-concepts.md) if unfamiliar with ML workflows
2. **Using AI assistants?** See [AI Learning Prompts](docs/ai-learning-prompts.md) for active learning strategies
3. Follow the [Sequential Learning Path](#sequential-learning-path)
4. Explore dashboards in Metabase

### For Experienced Developers

Jump directly to the relevant [Exploration Route](#quick-navigation) based on your task.

---

## Cross-Reference

- Full Onboarding Specification: `onboarding-spec.md`
- Training & Fine-Tuning Specification: `training-spec.md`

---

**TODO**: Add links to actual infrastructure endpoints once deployed.

