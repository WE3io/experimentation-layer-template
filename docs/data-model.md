# Data Model

**Purpose**  
This document defines the PostgreSQL schema used by the experimentation and model lifecycle system.

---

## Start Here If…

- **Full sequential workflow** → Continue from [architecture.md](architecture.md)
- **Experimentation only** → Focus on sections 1–2, then go to [experiments.md](experiments.md)
- **Training/fine-tuning** → Focus on sections 2–3, then go to [training-workflow.md](training-workflow.md)
- **Data model deep dive** → Read all sections

---

## Schema Overview

All tables use schema: `exp`

```
exp.experiments          ← Experiment definitions
exp.variants             ← Variants per experiment
exp.assignments          ← Unit → Variant mappings
exp.events               ← Raw event logs
exp.metric_aggregates    ← Hourly/daily summaries
exp.policies             ← Named policies
exp.policy_versions      ← Versioned policy configs linked to MLflow
exp.offline_replay_results ← Evaluation results
```

---

## 1. Experiments & Variants

### 1.1 exp.experiments

Stores experiment definitions.

```sql
-- TODO: Implement actual schema

CREATE TABLE exp.experiments (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(255) NOT NULL UNIQUE,
    description     TEXT,
    status          VARCHAR(50) NOT NULL DEFAULT 'draft',
                    -- draft | active | paused | completed
    unit_type       VARCHAR(50) NOT NULL,
                    -- user | household | session
    start_at        TIMESTAMP WITH TIME ZONE,
    end_at          TIMESTAMP WITH TIME ZONE,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_experiments_status ON exp.experiments(status);
CREATE INDEX idx_experiments_name ON exp.experiments(name);
```

### 1.2 exp.variants

Stores variants for each experiment.

```sql
-- TODO: Implement actual schema

CREATE TABLE exp.variants (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    experiment_id   UUID NOT NULL REFERENCES exp.experiments(id),
    name            VARCHAR(255) NOT NULL,
    description     TEXT,
    allocation      DECIMAL(5,4) NOT NULL,
                    -- 0.0000 to 1.0000 (percentage as decimal)
    config          JSONB NOT NULL DEFAULT '{}',
                    -- Unified config structure supporting both ML and conversational AI
                    -- See Config Structure section below for details
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(experiment_id, name)
);

-- Indexes
CREATE INDEX idx_variants_experiment ON exp.variants(experiment_id);
```

#### Config Structure

The `config` JSONB field supports a unified abstraction that works for both traditional ML projects and conversational AI projects. The structure is flexible and can represent different execution strategies.

**Unified Config Schema:**

The config can use one of three execution strategies:

1. **`mlflow_model`** - For traditional ML projects using trained models
2. **`prompt_template`** - For conversational AI projects using prompts and flows
3. **`hybrid`** - For projects combining both approaches

**Execution Strategy Field:**

- **`execution_strategy`** (optional, string): Specifies how the variant should be executed
  - Valid values: `"mlflow_model"`, `"prompt_template"`, `"hybrid"`
  - If omitted, the system assumes `"mlflow_model"` for backward compatibility

**ML Model Configuration (`mlflow_model` execution strategy):**

```json
{
  "execution_strategy": "mlflow_model",
  "mlflow_model": {
    "policy_version_id": "uuid-policy-version",
    "model_name": "planner_model"
  },
  "params": {
    "exploration_rate": 0.15,
    "temperature": 0.7,
    "max_tokens": 2048
  }
}
```

- **`mlflow_model`** (object, required when `execution_strategy` is `"mlflow_model"` or `"hybrid"`):
  - **`policy_version_id`** (string, UUID): Reference to `exp.policy_versions.id`
  - **`model_name`** (string, optional): MLflow model name for reference

**Prompt Template Configuration (`prompt_template` execution strategy):**

```json
{
  "execution_strategy": "prompt_template",
  "prompt_config": {
    "prompt_version_id": "uuid-prompt-v1",
    "model_provider": "anthropic",
    "model_name": "claude-sonnet-4.5"
  },
  "flow_config": {
    "flow_id": "onboarding_v1",
    "initial_state": "welcome"
  },
  "params": {
    "temperature": 0.7,
    "max_tokens": 2048
  }
}
```

- **`prompt_config`** (object, required when `execution_strategy` is `"prompt_template"` or `"hybrid"`):
  - **`prompt_version_id`** (string, UUID): Reference to `exp.prompt_versions.id`
  - **`model_provider`** (string): LLM provider (e.g., `"anthropic"`, `"openai"`)
  - **`model_name`** (string): Specific model identifier (e.g., `"claude-sonnet-4.5"`, `"gpt-4"`)

- **`flow_config`** (object, optional): Conversation flow configuration
  - **`flow_id`** (string): Identifier for the conversation flow definition
  - **`initial_state`** (string): Starting state in the flow state machine

**Shared Parameters:**

- **`params`** (object, optional): Runtime parameters applied to the execution
  - Common parameters: `temperature`, `max_tokens`, `top_p`, etc.
  - Parameters are execution-strategy agnostic and can be used with any strategy

**Backward Compatibility:**

The system maintains full backward compatibility with existing ML projects. The legacy format without `execution_strategy` is still supported:

```json
{
  "policy_version_id": "uuid-policy-version",
  "params": {
    "exploration_rate": 0.15,
    "temperature": 0.7
  }
}
```

When `execution_strategy` is omitted, the system automatically treats the config as `execution_strategy: "mlflow_model"` and extracts `policy_version_id` from the root level. This ensures existing experiments continue to work without modification.

**Example Configurations:**

**Traditional ML Experiment:**
```json
{
  "execution_strategy": "mlflow_model",
  "mlflow_model": {
    "policy_version_id": "550e8400-e29b-41d4-a716-446655440000",
    "model_name": "planner_model"
  },
  "params": {
    "temperature": 0.7,
    "exploration_rate": 0.15
  }
}
```

**Conversational AI Experiment:**
```json
{
  "execution_strategy": "prompt_template",
  "prompt_config": {
    "prompt_version_id": "660e8400-e29b-41d4-a716-446655440001",
    "model_provider": "anthropic",
    "model_name": "claude-sonnet-4.5"
  },
  "flow_config": {
    "flow_id": "onboarding_v1",
    "initial_state": "welcome"
  },
  "params": {
    "temperature": 0.7,
    "max_tokens": 2048
  }
}
```

**Hybrid Experiment (combining both):**
```json
{
  "execution_strategy": "hybrid",
  "mlflow_model": {
    "policy_version_id": "550e8400-e29b-41d4-a716-446655440000",
    "model_name": "planner_model"
  },
  "prompt_config": {
    "prompt_version_id": "660e8400-e29b-41d4-a716-446655440001",
    "model_provider": "anthropic",
    "model_name": "claude-sonnet-4.5"
  },
  "params": {
    "temperature": 0.7
  }
}
```

### 1.3 exp.assignments

Stores deterministic unit → variant mappings.

```sql
-- TODO: Implement actual schema

CREATE TABLE exp.assignments (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    experiment_id   UUID NOT NULL REFERENCES exp.experiments(id),
    unit_type       VARCHAR(50) NOT NULL,
    unit_id         VARCHAR(255) NOT NULL,
    variant_id      UUID NOT NULL REFERENCES exp.variants(id),
    assigned_at     TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(experiment_id, unit_id)
);

-- Indexes
CREATE INDEX idx_assignments_unit ON exp.assignments(unit_type, unit_id);
CREATE INDEX idx_assignments_experiment ON exp.assignments(experiment_id);
```

---

## 2. Events & Metrics

### 2.1 exp.events

Atomic logs of in-product actions.

```sql
-- TODO: Implement actual schema

CREATE TABLE exp.events (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_type      VARCHAR(100) NOT NULL,
                    -- plan_generated | plan_accepted | meal_swapped | etc.
    unit_type       VARCHAR(50) NOT NULL,
    unit_id         VARCHAR(255) NOT NULL,
    experiments     JSONB NOT NULL DEFAULT '[]',
                    -- Array of {experiment_id, variant_id}
    context         JSONB NOT NULL DEFAULT '{}',
                    -- policy_version_id, app_version, etc.
    metrics         JSONB NOT NULL DEFAULT '{}',
                    -- latency_ms, token_count, etc.
    payload         JSONB,
                    -- Event-specific data
    timestamp       TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for query patterns
CREATE INDEX idx_events_type ON exp.events(event_type);
CREATE INDEX idx_events_unit ON exp.events(unit_type, unit_id);
CREATE INDEX idx_events_timestamp ON exp.events(timestamp);
CREATE INDEX idx_events_experiments ON exp.events USING GIN(experiments);
```

**Event Structure Example**:
```json
{
  "event_type": "plan_generated",
  "unit_type": "user",
  "unit_id": "user-123",
  "experiments": [
    {"experiment_id": "uuid-exp", "variant_id": "uuid-var"}
  ],
  "context": {
    "policy_version_id": "uuid-policy-version",
    "app_version": "1.2.3"
  },
  "metrics": {
    "latency_ms": 450,
    "token_count": 1200
  },
  "timestamp": "2025-01-01T10:00:00Z"
}
```

### 2.2 exp.metric_aggregates

Hourly/daily summaries generated by pipelines.

```sql
-- TODO: Implement actual schema

CREATE TABLE exp.metric_aggregates (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    experiment_id   UUID NOT NULL REFERENCES exp.experiments(id),
    variant_id      UUID NOT NULL REFERENCES exp.variants(id),
    metric_name     VARCHAR(100) NOT NULL,
    bucket_type     VARCHAR(20) NOT NULL,
                    -- hourly | daily
    bucket_start    TIMESTAMP WITH TIME ZONE NOT NULL,
    count           BIGINT NOT NULL DEFAULT 0,
    sum             DECIMAL(20,6),
    mean            DECIMAL(20,6),
    min             DECIMAL(20,6),
    max             DECIMAL(20,6),
    stddev          DECIMAL(20,6),
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(experiment_id, variant_id, metric_name, bucket_type, bucket_start)
);

-- Indexes
CREATE INDEX idx_aggregates_lookup ON exp.metric_aggregates(
    experiment_id, variant_id, metric_name, bucket_start
);
```

---

## 3. Policy & Model Registry Linking

### 3.1 exp.policies

Named policies (e.g., planner policy).

```sql
-- TODO: Implement actual schema

CREATE TABLE exp.policies (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(255) NOT NULL UNIQUE,
    description     TEXT,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 3.2 exp.policy_versions

Versioned references to MLflow model versions.

```sql
-- TODO: Implement actual schema

CREATE TABLE exp.policy_versions (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    policy_id           UUID NOT NULL REFERENCES exp.policies(id),
    version             INTEGER NOT NULL,
    mlflow_model_name   VARCHAR(255) NOT NULL,
    mlflow_model_version VARCHAR(50) NOT NULL,
    config_defaults     JSONB NOT NULL DEFAULT '{}',
    status              VARCHAR(50) NOT NULL DEFAULT 'active',
                        -- active | deprecated | archived
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(policy_id, version)
);

-- Indexes
CREATE INDEX idx_policy_versions_policy ON exp.policy_versions(policy_id);
CREATE INDEX idx_policy_versions_mlflow ON exp.policy_versions(mlflow_model_name, mlflow_model_version);
```

**Policy Version Example**:
```json
{
  "policy_id": "planner_policy",
  "version": 4,
  "mlflow_model_name": "planner_model",
  "mlflow_model_version": "4",
  "config_defaults": {
    "temperature": 0.7,
    "max_tokens": 2048
  }
}
```

---

## 4. Offline Evaluation

### 4.1 exp.offline_replay_results

Stores offline evaluation results.

```sql
-- TODO: Implement actual schema

CREATE TABLE exp.offline_replay_results (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    policy_version_id       UUID NOT NULL REFERENCES exp.policy_versions(id),
    dataset_version         VARCHAR(255) NOT NULL,
    mlflow_run_id           VARCHAR(255),
    
    -- Aggregate metrics
    plan_alignment_score    DECIMAL(10,6),
    constraint_respect_score DECIMAL(10,6),
    edit_distance_score     DECIMAL(10,6),
    diversity_score         DECIMAL(10,6),
    leftovers_score         DECIMAL(10,6),
    
    -- Comparison
    baseline_version_id     UUID REFERENCES exp.policy_versions(id),
    is_better_than_baseline BOOLEAN,
    
    -- Status
    status                  VARCHAR(50) NOT NULL DEFAULT 'completed',
    error_message           TEXT,
    
    created_at              TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_replay_policy ON exp.offline_replay_results(policy_version_id);
CREATE INDEX idx_replay_dataset ON exp.offline_replay_results(dataset_version);
```

---

## 5. Useful Views

### 5.1 Experiment Metrics View

```sql
-- TODO: Create as part of infra setup

CREATE VIEW exp.v_experiment_metrics AS
SELECT
    e.name AS experiment_name,
    v.name AS variant_name,
    m.metric_name,
    m.mean,
    m.count,
    m.bucket_start
FROM exp.metric_aggregates m
JOIN exp.variants v ON v.id = m.variant_id
JOIN exp.experiments e ON e.id = m.experiment_id;
```

### 5.2 Active Experiments View

```sql
-- TODO: Create as part of infra setup

CREATE VIEW exp.v_active_experiments AS
SELECT
    e.*,
    COUNT(v.id) AS variant_count,
    SUM(v.allocation) AS total_allocation
FROM exp.experiments e
LEFT JOIN exp.variants v ON v.experiment_id = e.id
WHERE e.status = 'active'
GROUP BY e.id;
```

---

## 6. Entity Relationships

```
exp.experiments
    │
    ├──< exp.variants (1:N)
    │       │
    │       └──< exp.assignments (1:N)
    │       │
    │       └──< exp.metric_aggregates (1:N)
    │
    └──< exp.events (via JSONB experiments array)

exp.policies
    │
    └──< exp.policy_versions (1:N)
            │
            └──< exp.offline_replay_results (1:N)
            │
            └──< exp.variants.config.policy_version_id (FK reference)
```

---

## Further Exploration

- **Understand experiment configuration** → [experiments.md](experiments.md)
- **See full schema file** → [../infra/postgres-schema-overview.sql](../infra/postgres-schema-overview.sql)
- **Learn about event logging** → [event-ingestion-service.md](event-ingestion-service.md)

---

## After Completing This Document

You will understand:
- The complete PostgreSQL schema
- How experiments, variants, and assignments relate
- How events and metrics are stored
- How policies link to MLflow models

**Next Step**: [experiments.md](experiments.md)

