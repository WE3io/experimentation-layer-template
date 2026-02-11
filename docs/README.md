# Documentation Index

**Purpose**  
This directory contains all core documentation for the experimentation and model lifecycle system.

---

## Start Here If…

| Your Goal | Start With |
|-----------|------------|
| Starting a new project | [choosing-project-type.md](choosing-project-type.md) → choose ML or conversational AI |
| Understand the full system | [architecture.md](architecture.md) → follow sequential path |
| Define or run experiments | [experiments.md](experiments.md) |
| Log events from your service | [event-ingestion-service.md](event-ingestion-service.md) |
| Train or fine-tune models | [training-workflow.md](training-workflow.md) |
| Evaluate models offline | [offline-evaluation.md](offline-evaluation.md) |
| Promote models to production | [model-promotion.md](model-promotion.md) |
| Learn MLOps basics | [mlops-concepts.md](mlops-concepts.md) |
| Learning with AI assistants | [ai-learning-prompts.md](ai-learning-prompts.md) |

---

## Learning with AI Assistants

If you're using AI coding assistants while learning this system, see **[ai-learning-prompts.md](ai-learning-prompts.md)** for prompt templates that keep you actively engaged rather than passively consuming answers.

The guide includes prompts for:
- Verifying comprehension
- Making predictions before reading
- Designing solutions yourself first
- Debugging systematically
- Teaching concepts back
- And more

**Key principle**: Do 70% of the thinking yourself, use AI for the remaining 30% (review, critique, fill gaps).

---

## Sequential Learning Path

Complete these in order for full understanding:

### Phase 0: Project Setup
0. **[choosing-project-type.md](choosing-project-type.md)**  
   Choose between ML and conversational AI approaches

### Phase 1: Foundation
1. **[architecture.md](architecture.md)**  
   System components and data flow
   
2. **[data-model.md](data-model.md)**  
   PostgreSQL schema and relationships

### Phase 2: Experimentation
3. **[experiments.md](experiments.md)**  
   Experiment concepts, variants, and allocation

4. **[assignment-service.md](assignment-service.md)**  
   How users get assigned to variants

5. **[event-ingestion-service.md](event-ingestion-service.md)**  
   How events are logged and stored

### Phase 3: Model Lifecycle
6. **[mlflow-guide.md](mlflow-guide.md)**  
   Model registry, tracking, and versioning

7. **[training-workflow.md](training-workflow.md)**  
   Dataset preparation and training process

8. **[offline-evaluation.md](offline-evaluation.md)**  
   Replay evaluation before live traffic

9. **[model-promotion.md](model-promotion.md)**  
   Moving models through candidate → production

### Phase 4: Conversational AI (New)
10. **[prompts-guide.md](prompts-guide.md)**  
    Prompt management and versioning for conversational AI
    
11. **[conversation-flows.md](conversation-flows.md)**  
    Conversation flow orchestration and state machines
    
12. **[mcp-integration.md](mcp-integration.md)**  
    MCP integration for external tools and data sources

### Phase 5: Monitoring
13. **[../analytics/metabase-models.md](../analytics/metabase-models.md)**  
    Dashboards and metrics visualisation

---

## Parallel Exploration Routes

For developers who want to dive into specific areas:

| Route | Description | Entry Point |
|-------|-------------|-------------|
| [Experiment Route](routes/experiment-route.md) | Define and run experiments | experiments.md |
| [Conversational AI Route](routes/conversational-ai-route.md) | Build chatbots and LLM assistants | choosing-project-type.md |
| [Event Logging Route](routes/event-logging-route.md) | Capture and aggregate events | event-ingestion-service.md |
| [Training Route](routes/training-route.md) | Prepare data, train models | training-workflow.md |
| [Offline Evaluation Route](routes/offline-evaluation-route.md) | Validate models before deployment | offline-evaluation.md |
| [Model Promotion Route](routes/model-promotion-route.md) | Promote models safely | model-promotion.md |
| [Analytics Route](routes/analytics-route.md) | Build dashboards, analyse results | ../analytics/metabase-models.md |

---

## File Reference

| File | Purpose |
|------|---------|
| `choosing-project-type.md` | Decision guide for ML vs. conversational AI |
| `architecture.md` | System overview and component relationships |
| `data-model.md` | PostgreSQL schema definitions |
| `experiments.md` | Experiment concepts and configuration |
| `assignment-service.md` | Variant assignment logic |
| `event-ingestion-service.md` | Event logging patterns |
| `mlflow-guide.md` | MLflow usage and conventions |
| `training-workflow.md` | Training and fine-tuning process |
| `offline-evaluation.md` | Replay evaluation methodology |
| `model-promotion.md` | Promotion lifecycle |
| `mlops-concepts.md` | Primer for developers new to MLOps |
| `ai-learning-prompts.md` | Prompts for active learning with AI assistants |
| `prompts-guide.md` | Prompt management and versioning for conversational AI |
| `conversation-flows.md` | Conversation flow orchestration and state machines |
| `mcp-integration.md` | MCP (Model Context Protocol) integration guide |

---

## After Completing This Documentation

You will understand:
- How experiments control which users see which variants (for both ML and conversational AI)
- How events flow from application to analytics (including conversation events)
- How models are trained, evaluated, and promoted (ML projects)
- How prompts and flows are managed and versioned (conversational AI projects)
- How to build chatbots and LLM assistants using the platform
- How to monitor experiment results for both project types

**Next Step**: Start with [architecture.md](architecture.md)

