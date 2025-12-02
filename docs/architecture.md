# Architecture Overview

**Purpose**  
This document describes the system architecture, core components, and their relationships.

---

## Start Here If…

- **Full sequential workflow** → Read this first, then proceed to [data-model.md](data-model.md)
- **Experimentation only** → Skip to [experiments.md](experiments.md)
- **Training/fine-tuning** → Skip to [training-workflow.md](training-workflow.md)

---

## 1. System Capabilities

The system provides three core capabilities:

### 1.1 Experimentation Layer
- Controls which planner/policy/model variant each user or household receives
- Stores experiment configurations, variant allocation rules, and assignments
- Ensures deterministic assignment and consistent behaviour

### 1.2 Event Logging & Metrics Layer
- Records plan generation, user interactions, performance metrics, and variant context
- Serves as the foundation for offline datasets and analytics

### 1.3 Model Training, Fine-Tuning, and Evaluation Workflow
- Generates training datasets from logs
- Runs model training with MLflow
- Performs offline replay evaluation
- Promotes model versions into controlled experiments, then production

---

## 2. Component Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                              Client                                  │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                              Backend                                 │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │              Experiment Assignment Service (EAS)             │   │
│  │         → Determines variant for each unit (user/household)  │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                    │                                 │
│                                    ▼                                 │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │              Policy + Model Selection Layer                  │   │
│  │         → Loads model version based on variant config        │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                    │                                 │
│                                    ▼                                 │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                     Planner Execution                        │   │
│  │         → Generates plans using selected model               │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                    │                                 │
│                                    ▼                                 │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │              Event Ingestion Service (EIS)                   │   │
│  │         → Records all events with experiment context         │   │
│  └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                          PostgreSQL                                  │
│  ┌───────────────┐ ┌───────────────┐ ┌───────────────────────────┐ │
│  │  exp.events   │ │exp.assignments│ │   exp.experiments         │ │
│  └───────────────┘ └───────────────┘ └───────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
          │                                           │
          ▼                                           ▼
┌─────────────────────────┐              ┌─────────────────────────┐
│        Metabase         │              │   Offline Pipelines     │
│    (Dashboards)         │              │   (Airflow/Prefect)     │
└─────────────────────────┘              └─────────────────────────┘
                                                      │
                                                      ▼
                                         ┌─────────────────────────┐
                                         │         MLflow          │
                                         │   (Model Registry +     │
                                         │    Experiment Tracking) │
                                         └─────────────────────────┘
                                                      │
                                                      ▼
                                         ┌─────────────────────────┐
                                         │      S3/MinIO           │
                                         │   (Datasets + Artefacts)│
                                         └─────────────────────────┘
```

---

## 3. Component Responsibilities

### 3.1 Experiment Assignment Service (EAS)
- Variant assignment and config delivery
- Deterministic hashing of unit IDs
- Assignment persistence

**Related**: [assignment-service.md](assignment-service.md), [../services/assignment-service/](../services/assignment-service/)

### 3.2 Event Ingestion Service (EIS)
- Event recording and validation
- Experiment context attachment
- Long-term storage

**Related**: [event-ingestion-service.md](event-ingestion-service.md), [../services/event-ingestion-service/](../services/event-ingestion-service/)

### 3.3 PostgreSQL
- Metadata storage
- Event logs
- Experiment configurations

**Related**: [data-model.md](data-model.md), [../infra/postgres-schema-overview.sql](../infra/postgres-schema-overview.sql)

### 3.4 MLflow
- Model versions
- Training runs
- Artefact storage

**Related**: [mlflow-guide.md](mlflow-guide.md), [../infra/mlflow-setup.md](../infra/mlflow-setup.md)

### 3.5 Metabase
- Visibility and decision support
- Experiment dashboards
- Metric visualisation

**Related**: [../analytics/metabase-models.md](../analytics/metabase-models.md), [../infra/metabase-setup.md](../infra/metabase-setup.md)

### 3.6 Pipelines
- Dataset generation
- Metrics aggregation
- Offline evaluation

**Related**: [../pipelines/](../pipelines/)

---

## 4. Data Flow Summary

### 4.1 Request Flow
1. Client makes request
2. Backend calls EAS for variant assignment
3. EAS returns variant config (including policy version)
4. Backend loads model from policy version
5. Planner executes with model
6. EIS records event with experiment context

### 4.2 Training Flow
1. Pipeline extracts events from PostgreSQL
2. Pipeline builds training dataset
3. Training job runs with MLflow tracking
4. Model registered in MLflow
5. Policy version created linking to model
6. Experiment variant created with policy version

### 4.3 Promotion Flow
1. Offline evaluation runs against candidate model
2. If passes: mark as candidate in MLflow
3. Create experiment variant with small allocation
4. Monitor via Metabase
5. If successful: increase allocation, promote to production

---

## 5. Further Exploration

- **Deep dive into data structures** → [data-model.md](data-model.md)
- **Understand experiment mechanics** → [experiments.md](experiments.md)
- **Learn about model lifecycle** → [mlflow-guide.md](mlflow-guide.md)

---

## After Completing This Document

You will understand:
- The major system components
- How they interact
- The three main data flows (request, training, promotion)

**Next Step**: [data-model.md](data-model.md)

