# Architecture Overview

**Purpose**  
This document describes the system architecture, core components, and their relationships.

---

## Start Here If…

- **Full sequential workflow** → Read this first, then proceed to [data-model.md](data-model.md)
- **Starting a new project** → Start with [choosing-project-type.md](choosing-project-type.md) to choose ML or conversational AI
- **Experimentation only** → Skip to [experiments.md](experiments.md)
- **Building conversational AI** → See [routes/conversational-ai-route.md](routes/conversational-ai-route.md) for quickstart
- **Training/fine-tuning models** → Skip to [training-workflow.md](training-workflow.md)

---

## 1. System Capabilities

The system provides unified experimentation capabilities for both traditional ML projects and conversational AI projects:

### 1.1 Experimentation Layer
- Controls which variant each user or household receives (models, prompts, or flows)
- Supports unified variant configuration with multiple execution strategies:
  - **ML Models**: Trained models from MLflow Model Registry
  - **Prompt Templates**: Versioned prompts with LLM providers
  - **Conversation Flows**: State machine-based dialogue orchestration
- Stores experiment configurations, variant allocation rules, and assignments
- Ensures deterministic assignment and consistent behaviour

### 1.2 Event Logging & Metrics Layer
- Records plan generation, user interactions, conversation events, performance metrics, and variant context
- Supports both ML events (model predictions, training metrics) and conversation events (message exchanges, flow transitions, completions)
- Serves as the foundation for offline datasets and analytics

### 1.3 Model Training, Fine-Tuning, and Evaluation Workflow
- Generates training datasets from logs
- Runs model training with MLflow (for ML projects)
- Performs offline replay evaluation (for both ML and conversational AI)
- Promotes model versions or prompt versions into controlled experiments, then production

---

## 2. Component Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                              Client                                  │
│  (ML Applications / Conversational AI Applications)                │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                              Backend                                 │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │              Experiment Assignment Service (EAS)             │   │
│  │  → Determines variant for each unit (user/household/session) │   │
│  │  → Returns unified config (mlflow_model | prompt_template)   │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                    │                                 │
│                    ┌───────────────┴───────────────┐                │
│                    │                               │                │
│                    ▼                               ▼                │
│  ┌─────────────────────────────┐   ┌─────────────────────────────┐ │
│  │   ML Execution Path         │   │  Conversational AI Path    │ │
│  │                             │   │                             │ │
│  │  ┌───────────────────────┐ │   │  ┌───────────────────────┐   │ │
│  │  │ Policy + Model        │ │   │  │  Prompt Service      │   │ │
│  │  │ Selection Layer       │ │   │  │  → Retrieves prompt  │   │ │
│  │  │ → Loads model from    │ │   │  │    versions by ID    │   │ │
│  │  │   MLflow              │ │   │  │  → Loads content     │   │ │
│  │  └───────────────────────┘ │   │  │    from /prompts/    │   │ │
│  │            │                │   │  └───────────────────────┘   │ │
│  │            ▼                │   │            │                 │ │
│  │  ┌───────────────────────┐ │   │            ▼                 │ │
│  │  │ Planner Execution     │ │   │  ┌───────────────────────┐   │ │
│  │  │ → Generates plans     │ │   │  │ Flow Orchestrator    │   │ │
│  │  │   using selected      │ │   │  │ → Manages flow       │   │ │
│  │  │   model               │ │   │  │   state machines      │   │ │
│  │  └───────────────────────┘ │   │  │ → Session management │   │ │
│  │                             │   │  │   (Redis)            │   │ │
│  │                             │   │  │ → State transitions  │   │ │
│  │                             │   │  └───────────────────────┘   │ │
│  └─────────────────────────────┘   └─────────────────────────────┘ │
│                    │                               │                │
│                    └───────────────┬───────────────┘                │
│                                    ▼                                 │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │              Event Ingestion Service (EIS)                   │   │
│  │  → Records all events with experiment context                │   │
│  │  → Supports ML events & conversation events                  │   │
│  └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                          PostgreSQL                                  │
│  ┌───────────────┐ ┌───────────────┐ ┌───────────────────────────┐ │
│  │  exp.events   │ │exp.assignments│ │   exp.experiments         │ │
│  └───────────────┘ └───────────────┘ └───────────────────────────┘ │
│  ┌───────────────┐ ┌───────────────┐ ┌───────────────────────────┐ │
│  │exp.prompts    │ │exp.prompt_    │ │   exp.policy_versions     │ │
│  │               │ │  versions     │ │                           │ │
│  └───────────────┘ └───────────────┘ └───────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
          │                                           │
          ▼                                           ▼
┌─────────────────────────┐              ┌─────────────────────────┐
│        Metabase         │              │   Offline Pipelines     │
│    (Dashboards)         │              │   (Airflow/Prefect)     │
│  - ML Metrics           │              │  - Training datasets    │
│  - Conversation Metrics │              │  - Conversation replay   │
└─────────────────────────┘              └─────────────────────────┘
          │                                           │
          │                                           ▼
          │                              ┌─────────────────────────┐
          │                              │         MLflow          │
          │                              │   (Model Registry +     │
          │                              │    Experiment Tracking) │
          │                              └─────────────────────────┘
          │                                           │
          │                                           ▼
          │                              ┌─────────────────────────┐
          │                              │      S3/MinIO           │
          │                              │   (Datasets + Artefacts)│
          │                              └─────────────────────────┘
          │
          ▼
┌─────────────────────────┐
│         Redis           │
│   (Session Storage)     │
│  - Conversation state   │
│  - Flow context         │
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

### 3.6 Prompt Service
- Prompt version retrieval by ID
- Prompt content loading from Git-versioned files in `/prompts/` directory
- Version management and metadata tracking
- Caching for performance

**Related**: [../services/prompt-service/](../services/prompt-service/), [prompts-guide.md](prompts-guide.md)

### 3.7 Flow Orchestrator
- Conversation flow execution as state machines
- Session management with Redis-backed state storage
- State transitions and condition evaluation
- Input validation and action execution
- Flow definition loading from `/flows/` directory

**Related**: [../services/flow-orchestrator/](../services/flow-orchestrator/), [conversation-flows.md](conversation-flows.md)

### 3.8 Redis
- Conversation session storage
- Flow state persistence with expiry
- Temporary context tracking

**Related**: [../infra/redis-setup.md](../infra/redis-setup.md) (if exists)

### 3.9 Pipelines
- Dataset generation (for ML projects)
- Conversation replay (for conversational AI projects)
- Metrics aggregation
- Offline evaluation

**Related**: [../pipelines/](../pipelines/)

---

## 4. Data Flow Summary

### 4.1 ML Request Flow (Traditional ML Projects)
1. Client makes request (e.g., plan generation)
2. Backend calls EAS for variant assignment
3. EAS returns variant config with `execution_strategy: "mlflow_model"`
4. Backend loads model from MLflow using `policy_version_id`
5. Planner executes with model
6. EIS records event with experiment context

### 4.2 Conversational AI Request Flow
1. Client initiates conversation or sends message
2. Backend calls EAS for variant assignment
3. EAS returns variant config with `execution_strategy: "prompt_template"`
4. Backend retrieves prompt version from Prompt Service using `prompt_version_id`
5. If flow is configured, Flow Orchestrator manages conversation state:
   - Loads or creates session in Redis
   - Evaluates current state and transitions
   - Validates user input
   - Executes actions and updates state
6. Backend calls LLM API with prompt template and conversation context
7. EIS records conversation events (message_sent, flow_transition, etc.) with experiment context

### 4.3 Training Flow (ML Projects)
1. Pipeline extracts events from PostgreSQL
2. Pipeline builds training dataset
3. Training job runs with MLflow tracking
4. Model registered in MLflow
5. Policy version created linking to model
6. Experiment variant created with policy version

### 4.4 Prompt Versioning Flow (Conversational AI Projects)
1. Prompt template created/updated in `/prompts/` directory
2. Prompt version registered in PostgreSQL (`exp.prompt_versions`)
3. Prompt version linked to experiment variant via `prompt_version_id` in variant config
4. Prompt Service retrieves and serves prompt content
5. Changes tracked via Git version control

### 4.5 Promotion Flow (ML Projects)
1. Offline evaluation runs against candidate model
2. If passes: mark as candidate in MLflow
3. Create experiment variant with small allocation
4. Monitor via Metabase
5. If successful: increase allocation, promote to production

### 4.6 Promotion Flow (Conversational AI Projects)
1. Conversation replay evaluation runs against candidate prompt/flow
2. If passes: mark prompt version as candidate
3. Create experiment variant with small allocation
4. Monitor conversation metrics via Metabase (completion rate, satisfaction, etc.)
5. If successful: increase allocation, promote to production

---

## 5. Unified Abstraction: How Conversational AI Integrates

The system uses a unified variant configuration abstraction that supports both ML and conversational AI projects through execution strategies:

### 5.1 Execution Strategies

The variant `config` field supports three execution strategies:

| Execution Strategy | Use Case | Key Components |
|-------------------|----------|----------------|
| `mlflow_model` | Traditional ML projects | MLflow, Policy Versions, Trained Models |
| `prompt_template` | Conversational AI projects | Prompt Service, Flow Orchestrator, LLM APIs |
| `hybrid` | Combined approaches | Both ML models and prompts in same variant |

### 5.2 How It Works

1. **Unified Assignment**: EAS returns variant configs with `execution_strategy` field
2. **Strategy-Specific Execution**: Backend routes to appropriate execution path:
   - `mlflow_model` → Load model from MLflow → Execute planner
   - `prompt_template` → Load prompt from Prompt Service → Execute flow (if configured) → Call LLM
3. **Unified Event Logging**: EIS records all events (ML or conversation) with experiment context
4. **Unified Analytics**: Metabase dashboards support both ML metrics and conversation metrics

### 5.3 Benefits

- **Single Experimentation Framework**: Same A/B testing infrastructure for both project types
- **Consistent Patterns**: Deterministic assignment, variant allocation, and statistical validity
- **Flexible Configuration**: Projects can mix strategies or migrate between them
- **Backward Compatible**: Existing ML projects continue working without changes

**Related**: [data-model.md](data-model.md) (section on Config Structure), [experiments.md](experiments.md)

---

## 6. Further Exploration

- **Deep dive into data structures** → [data-model.md](data-model.md)
- **Understand experiment mechanics** → [experiments.md](experiments.md)
- **Learn about model lifecycle** → [mlflow-guide.md](mlflow-guide.md)
- **Prompt management** → [prompts-guide.md](prompts-guide.md)
- **Conversation flows** → [conversation-flows.md](conversation-flows.md)
- **MCP integration** → [mcp-integration.md](mcp-integration.md)
- **Example projects** → [../examples/README.md](../examples/README.md)
- **Conversational AI quickstart** → [routes/conversational-ai-route.md](routes/conversational-ai-route.md)

**See Also:**
- [choosing-project-type.md](choosing-project-type.md) - Help choosing between ML and conversational AI
- [routes/experiment-route.md](routes/experiment-route.md) - Experiment-focused learning path
- [routes/conversational-ai-route.md](routes/conversational-ai-route.md) - Conversational AI learning path

---

## After Completing This Document

You will understand:
- The major system components (including conversational AI services)
- How they interact (both ML and conversational AI paths)
- The unified abstraction supporting multiple execution strategies
- The main data flows (ML request, conversational AI request, training, promotion)

**Next Step**: [data-model.md](data-model.md)

