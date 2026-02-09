# Experimentation & Model Lifecycle Platform

**Purpose**  
This repository provides a unified foundation for experimentation, supporting both traditional ML projects (model training, fine-tuning, evaluation) and conversational AI projects (chatbots, LLM-powered assistants). It is designed for senior developers who may not have prior MLOps experience.

---

## Choose Your Project Type

This platform supports two project types through a unified experimentation framework:

| Project Type | Use Case | Execution Strategy | Quick Start |
|--------------|----------|-------------------|-------------|
| **Traditional ML** | Model training, fine-tuning, offline evaluation | `mlflow_model` | [Training Route](docs/routes/training-route.md) |
| **Conversational AI** | Chatbots, LLM assistants, structured dialogues | `prompt_template` | [Conversational AI Route](docs/routes/conversational-ai-route.md) |

**Not sure which to choose?** → [Choosing Project Type Guide](docs/choosing-project-type.md)

---

## Quick Navigation

### Start Here If…

| Your Goal | Entry Point |
|-----------|-------------|
| **Choose project type** | [Choosing Project Type](docs/choosing-project-type.md) |
| Learn the full system end-to-end | [Sequential Learning Path](#sequential-learning-path) |
| Build conversational AI | [Conversational AI Route](docs/routes/conversational-ai-route.md) |
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
│   ├── choosing-project-type.md       ← Project type decision guide
│   ├── architecture.md                ← System architecture
│   ├── data-model.md                  ← PostgreSQL schema
│   ├── experiments.md                 ← Experiment concepts
│   ├── prompts-guide.md               ← Prompt management (Conversational AI)
│   ├── conversation-flows.md          ← Flow orchestration (Conversational AI)
│   ├── assignment-service.md          ← Assignment service overview
│   ├── event-ingestion-service.md     ← Event service overview
│   ├── mlflow-guide.md                ← MLflow usage (ML projects)
│   ├── training-workflow.md           ← Training process (ML projects)
│   ├── offline-evaluation.md          ← Offline replay evaluation
│   ├── model-promotion.md             ← Promotion lifecycle
│   ├── mlops-concepts.md              ← MLOps primer
│   └── routes/                        ← Parallel exploration routes
│       ├── conversational-ai-route.md ← Conversational AI quickstart
│       └── ...
├── services/                          ← Service specifications
│   ├── assignment-service/
│   ├── event-ingestion-service/
│   ├── prompt-service/                ← Prompt retrieval (Conversational AI)
│   └── flow-orchestrator/             ← Conversation management (Conversational AI)
├── prompts/                           ← Prompt template files (Conversational AI)
├── flows/                             ← Conversation flow definitions (Conversational AI)
├── examples/                           ← End-to-end example projects
│   └── conversational-assistant/      ← Conversational AI example
├── infra/                             ← Infrastructure setup
├── pipelines/                         ← Pipeline specifications
├── training/                          ← Training templates (ML projects)
├── datasets/                          ← Dataset conventions (ML projects)
├── analytics/                         ← Metabase & queries
└── config/                            ← Configuration examples
```

---

## Core Stack

| Component | Purpose |
|-----------|---------|
| PostgreSQL | Primary metadata store (experiments, events, policies, prompts) |
| MLflow | Model registry and experiment tracking (ML projects) |
| Metabase | Dashboards and experiment visualisation |
| LLM Providers | Anthropic Claude, OpenAI GPT (Conversational AI) |
| Open-source LLMs | LLaMA, Mistral, Qwen, etc. (ML projects) |
| Redis | Session storage for conversation flows (Conversational AI) |
| Object Storage | S3/MinIO for datasets and ML artefacts |
| Orchestrator | Airflow or Prefect |
| Task Queue | Redis/worker for async jobs |
| Docker | Containerisation |

---

## Getting Started

### For New Developers

1. **Choose your project type**: Start with [Choosing Project Type](docs/choosing-project-type.md)
2. **Conversational AI projects**: Follow [Conversational AI Route](docs/routes/conversational-ai-route.md)
3. **ML projects**: Read [MLOps Concepts](docs/mlops-concepts.md) if unfamiliar with ML workflows
4. **Using AI assistants?** See [AI Learning Prompts](docs/ai-learning-prompts.md) for active learning strategies
5. Follow the [Sequential Learning Path](#sequential-learning-path) for complete understanding
6. Explore dashboards in Metabase
7. Check out [Example Projects](examples/README.md) for complete working examples

### For Experienced Developers

Jump directly to the relevant [Exploration Route](#quick-navigation) based on your task.

---

## Cross-Reference

- Full Onboarding Specification: `onboarding-spec.md`
- Training & Fine-Tuning Specification: `training-spec.md`

---

**TODO**: Add links to actual infrastructure endpoints once deployed.

