# MLOps Concepts Primer

**Purpose**  
This document provides foundational MLOps knowledge for developers new to machine learning operations.

---

## Start Here If…

- **New to MLOps** → Read this first
- **Familiar with MLOps** → Skip to [architecture.md](architecture.md)
- **Need specific concept** → Use the index below

---

## 1. What is MLOps?

MLOps (Machine Learning Operations) applies DevOps practices to machine learning systems:

| DevOps Concept | MLOps Equivalent |
|----------------|------------------|
| Code versioning | Model versioning |
| CI/CD pipelines | Training pipelines |
| Staging → Production | Candidate → Production |
| Monitoring | Model performance metrics |
| Rollback | Model rollback |

---

## 2. Key Concepts

### 2.1 Model Registry

A versioned store of trained models:
- Each model has a name (e.g., `planner_model`)
- Each version is immutable
- Metadata tracks parameters, metrics, artefacts

**In this system**: MLflow Model Registry

### 2.2 Experiment Tracking

Recording what happens during training:
- Parameters (learning rate, batch size)
- Metrics (loss, accuracy)
- Artefacts (model weights, configs)

**In this system**: MLflow Tracking

### 2.3 Feature Store

Centralised storage for ML features:
- Consistent feature computation
- Reuse across training and inference

**In this system**: PostgreSQL domain tables + event logs

### 2.4 Model Serving

Deploying models for inference:
- Low latency
- High availability
- Version management

**In this system**: Policy versions linked to MLflow models

### 2.5 A/B Testing

Comparing model variants:
- Split traffic between versions
- Measure performance differences
- Statistical significance

**In this system**: Experiment Assignment Service + variants

---

## 3. The ML Lifecycle

```
┌─────────────────────────────────────────────────────────────────────┐
│                                                                       │
│  ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐           │
│  │ Data    │ ──►│ Train   │ ──►│ Evaluate│ ──►│ Deploy  │           │
│  │ Prep    │    │         │    │         │    │         │           │
│  └─────────┘    └─────────┘    └─────────┘    └─────────┘           │
│       ▲                                              │               │
│       │                                              │               │
│       └──────────────────────────────────────────────┘               │
│                          Feedback Loop                                │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
```

### 3.1 Data Preparation
- Collect raw data (events, logs)
- Transform into training format
- Version datasets

### 3.2 Training
- Load data and base model
- Fine-tune or train from scratch
- Log everything to MLflow

### 3.3 Evaluation
- Offline replay against historical data
- Compare with baseline
- Gate before deployment

### 3.4 Deployment
- Create policy version
- Create experiment variant
- Gradual rollout

---

## 4. Common Terms

| Term | Definition |
|------|------------|
| **Artefact** | Any file produced by training (model, config, tokenizer) |
| **Baseline** | The current production model to compare against |
| **Candidate** | A model that passed offline eval, ready for online testing |
| **Epoch** | One complete pass through training data |
| **Fine-tuning** | Adapting a pre-trained model to a specific task |
| **Hyperparameter** | Training configuration (learning rate, batch size) |
| **Inference** | Using a model to make predictions |
| **LoRA** | Low-Rank Adaptation - efficient fine-tuning method |
| **QLoRA** | Quantized LoRA - memory-efficient fine-tuning |
| **Rollback** | Reverting to a previous model version |
| **Run** | A single training execution with specific parameters |

---

## 5. Why This Matters

### 5.1 Reproducibility
Every training run must be reproducible:
- Same data + same params = same model
- Version everything

### 5.2 Observability
Know what's happening at all times:
- Training progress
- Model performance
- Production metrics

### 5.3 Safety
Protect users from bad models:
- Offline evaluation gates
- Gradual rollouts
- Quick rollback capability

---

## 6. Related Documentation

| Document | Purpose |
|----------|---------|
| [mlflow-guide.md](mlflow-guide.md) | MLflow specifics |
| [training-workflow.md](training-workflow.md) | Training process |
| [offline-evaluation.md](offline-evaluation.md) | Evaluation gates |
| [model-promotion.md](model-promotion.md) | Deployment lifecycle |

---

## After Completing This Document

You will understand:
- Basic MLOps concepts
- The ML lifecycle
- Key terminology
- Why MLOps practices matter

**Next Step**: [architecture.md](architecture.md)

