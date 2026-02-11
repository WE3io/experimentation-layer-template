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
exp.prompts              ← Named prompts (conversational AI)
exp.prompt_versions      ← Versioned prompt configs linked to prompt files
exp.mcp_tools            ← MCP tools from configured servers
exp.variant_tools         ← Variant → Tool assignments (many-to-many)
exp.offline_replay_results ← Evaluation results
```

---

## 1. Experiments & Variants

### 1.1 exp.experiments

Stores experiment definitions. Columns: id, name, description, status, unit_type, start_at, end_at, created_at, updated_at.

**Full DDL:** [postgres-schema-overview.sql](../infra/postgres-schema-overview.sql) | **Migrations:** [infra/migrations/README.md](../infra/migrations/README.md)

### 1.2 exp.variants

Stores variants for each experiment. Columns: id, experiment_id, name, description, allocation, config (JSONB), created_at.

**Full DDL:** [postgres-schema-overview.sql](../infra/postgres-schema-overview.sql)

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

Stores deterministic unit → variant mappings. Columns: id, experiment_id, unit_type, unit_id, variant_id, assigned_at.

**Full DDL:** [postgres-schema-overview.sql](../infra/postgres-schema-overview.sql)

---

## 2. Events & Metrics

### 2.1 exp.events

Atomic logs of in-product actions. Columns: id, event_type, unit_type, unit_id, experiments (JSONB), context (JSONB), metrics (JSONB), payload (JSONB), timestamp, created_at.

**Full DDL:** [postgres-schema-overview.sql](../infra/postgres-schema-overview.sql)

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

#### Conversation Event Types

For conversational AI projects, the following event types are used to track conversation flows and user interactions:

| Event Type | Description | When Fired |
|------------|-------------|------------|
| `conversation_started` | User initiates a new conversation | When a new conversation session begins |
| `message_sent` | User or bot sends a message | On each message exchange in the conversation |
| `flow_completed` | User successfully completes a conversation flow | When flow reaches a terminal/end state |
| `user_dropped_off` | User abandons conversation without completion | When session expires or user stops responding |

**Conversation Context Fields:**

Conversation events include additional context fields in the `context` JSONB object:

- **`session_id`** (string): Unique identifier for the conversation session
- **`flow_id`** (string): Identifier of the conversation flow being executed
- **`flow_version`** (string, optional): Version of the flow definition
- **`current_state`** (string, optional): Current state in the flow state machine
- **`prompt_version_id`** (string, UUID, optional): Reference to `exp.prompt_versions.id` if using prompt templates
- **`model_provider`** (string, optional): LLM provider (e.g., `"anthropic"`, `"openai"`)
- **`model_name`** (string, optional): Specific model identifier (e.g., `"claude-sonnet-4.5"`)

**Conversation Event Examples:**

**conversation_started:**
```json
{
  "event_type": "conversation_started",
  "unit_type": "user",
  "unit_id": "user-123",
  "experiments": [
    {"experiment_id": "uuid-exp", "variant_id": "uuid-var"}
  ],
  "context": {
    "session_id": "session-abc123def456",
    "flow_id": "user_onboarding",
    "flow_version": "1.0.0",
    "prompt_version_id": "uuid-prompt-version",
    "model_provider": "anthropic",
    "model_name": "claude-sonnet-4.5",
    "app_version": "1.2.3"
  },
  "metrics": {},
  "payload": {
    "entry_point": "web_chat",
    "referral_source": "email_campaign"
  },
  "timestamp": "2025-01-01T10:00:00Z"
}
```

**message_sent:**
```json
{
  "event_type": "message_sent",
  "unit_type": "user",
  "unit_id": "user-123",
  "experiments": [
    {"experiment_id": "uuid-exp", "variant_id": "uuid-var"}
  ],
  "context": {
    "session_id": "session-abc123def456",
    "flow_id": "user_onboarding",
    "current_state": "ask_name",
    "prompt_version_id": "uuid-prompt-version",
    "model_provider": "anthropic",
    "model_name": "claude-sonnet-4.5"
  },
  "metrics": {
    "latency_ms": 850,
    "token_count": 245,
    "turn_number": 3
  },
  "payload": {
    "sender": "user",
    "message_text": "John Doe",
    "message_length": 8,
    "state_transition": true,
    "next_state": "ask_email"
  },
  "timestamp": "2025-01-01T10:00:15Z"
}
```

**flow_completed:**
```json
{
  "event_type": "flow_completed",
  "unit_type": "user",
  "unit_id": "user-123",
  "experiments": [
    {"experiment_id": "uuid-exp", "variant_id": "uuid-var"}
  ],
  "context": {
    "session_id": "session-abc123def456",
    "flow_id": "user_onboarding",
    "flow_version": "1.0.0",
    "current_state": "complete",
    "prompt_version_id": "uuid-prompt-version",
    "model_provider": "anthropic",
    "model_name": "claude-sonnet-4.5"
  },
  "metrics": {
    "total_turns": 8,
    "total_duration_seconds": 245,
    "completion_rate": 1.0
  },
  "payload": {
    "completion_reason": "success",
    "final_state": "complete",
    "data_collected": {
      "name": "John Doe",
      "email": "john.doe@example.com"
    }
  },
  "timestamp": "2025-01-01T10:04:05Z"
}
```

**user_dropped_off:**
```json
{
  "event_type": "user_dropped_off",
  "unit_type": "user",
  "unit_id": "user-123",
  "experiments": [
    {"experiment_id": "uuid-exp", "variant_id": "uuid-var"}
  ],
  "context": {
    "session_id": "session-abc123def456",
    "flow_id": "user_onboarding",
    "current_state": "ask_email",
    "prompt_version_id": "uuid-prompt-version",
    "model_provider": "anthropic",
    "model_name": "claude-sonnet-4.5"
  },
  "metrics": {
    "total_turns": 4,
    "total_duration_seconds": 120,
    "time_since_last_message_seconds": 300
  },
  "payload": {
    "drop_off_reason": "session_expired",
    "last_active_state": "ask_email",
    "progress": 0.5,
    "data_collected": {
      "name": "John Doe"
    }
  },
  "timestamp": "2025-01-01T10:05:00Z"
}
```

**Conversation Payload Structure:**

The `payload` field for conversation events contains event-specific data:

- **conversation_started**: Entry point, referral source, initial context
- **message_sent**: Message content, sender (user/bot), state transitions, turn number
- **flow_completed**: Completion reason, final state, collected data summary
- **user_dropped_off**: Drop-off reason, last active state, progress percentage, partial data collected

**Conversation Metrics:**

Common metrics tracked in the `metrics` JSONB field for conversation events:

- **`latency_ms`**: Response time in milliseconds (for message_sent events)
- **`token_count`**: Number of tokens used in LLM call
- **`turn_number`**: Sequential turn number in the conversation
- **`total_turns`**: Total number of turns in the conversation (for completion/drop-off events)
- **`total_duration_seconds`**: Total conversation duration
- **`time_since_last_message_seconds`**: Time since last user message (for drop-off detection)
- **`completion_rate`**: Progress indicator (0.0 to 1.0)

### 2.2 exp.metric_aggregates

Hourly/daily summaries generated by pipelines.

**Full DDL:** [postgres-schema-overview.sql](../infra/postgres-schema-overview.sql)

---

## 3. Policy & Model Registry Linking

### 3.1 exp.policies

Named policies (e.g., planner policy).

**Full DDL:** [postgres-schema-overview.sql](../infra/postgres-schema-overview.sql)

### 3.2 exp.policy_versions

Versioned references to MLflow model versions.

**Full DDL:** [postgres-schema-overview.sql](../infra/postgres-schema-overview.sql)

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

## 4. Prompt Registry (Conversational AI)

### 4.1 exp.prompts

Named prompts for conversational AI projects (e.g., meal planning assistant, customer support bot).

**Full DDL:** [postgres-schema-overview.sql](../infra/postgres-schema-overview.sql)

### 4.2 exp.prompt_versions

Versioned prompt configurations linked to prompt files in `/prompts/` directory.

**Full DDL:** [postgres-schema-overview.sql](../infra/postgres-schema-overview.sql)

**Prompt Version Example**:
```json
{
  "prompt_id": "meal_planning_assistant",
  "version": 1,
  "file_path": "prompts/meal_planning_v1.txt",
  "model_provider": "anthropic",
  "model_name": "claude-sonnet-4.5",
  "config_defaults": {
    "temperature": 0.7,
    "max_tokens": 2048
  },
  "status": "active"
}
```

**Relationship to Variant Configs:**

Prompt versions are referenced in variant configs via `prompt_config.prompt_version_id`:

```json
{
  "execution_strategy": "prompt_template",
  "prompt_config": {
    "prompt_version_id": "uuid-prompt-version",
    "model_provider": "anthropic",
    "model_name": "claude-sonnet-4.5"
  }
}
```

**File Storage:**

- Prompt content is stored in `/prompts/` directory (Git versioned)
- `file_path` field references the file relative to repository root
- Example: `prompts/meal_planning_v1.txt`
- Git provides version control and history for prompt content

**Status Values:**

| Status | Description |
|--------|-------------|
| `active` | Currently in use, can be assigned to variants |
| `deprecated` | No longer recommended, but still supported |
| `archived` | Retired, not available for new assignments |

---

## 5. MCP Tool Registry (Conversational AI)

### 5.1 exp.mcp_tools

MCP (Model Context Protocol) tools available for use in conversational AI projects. Tools are discovered from configured MCP servers and registered in the database for variant assignment.

**Full DDL:** [postgres-schema-overview.sql](../infra/postgres-schema-overview.sql)

**Tool Schema Structure:**

The `tool_schema` JSONB field stores the MCP tool definition schema:

```json
{
  "name": "query_database",
  "description": "Execute a SQL query against the database",
  "inputSchema": {
    "type": "object",
    "properties": {
      "query": {
        "type": "string",
        "description": "SQL query to execute"
      },
      "limit": {
        "type": "integer",
        "description": "Maximum number of rows to return",
        "default": 100
      }
    },
    "required": ["query"]
  }
}
```

**Capabilities Structure:**

The `capabilities` JSONB field stores metadata about tool capabilities:

```json
{
  "requires_auth": true,
  "rate_limited": true,
  "rate_limit_per_minute": 60,
  "supports_streaming": false,
  "timeout_seconds": 30
}
```

**Tool Example:**

```json
{
  "id": "770e8400-e29b-41d4-a716-446655440002",
  "name": "query_database",
  "description": "Execute SQL queries against the application database",
  "server_name": "database_server",
  "tool_schema": {
    "name": "query_database",
    "description": "Execute a SQL query against the database",
    "inputSchema": {
      "type": "object",
      "properties": {
        "query": {
          "type": "string",
          "description": "SQL query to execute"
        }
      },
      "required": ["query"]
    }
  },
  "capabilities": {
    "requires_auth": true,
    "rate_limited": true,
    "rate_limit_per_minute": 60
  },
  "status": "active"
}
```

### 5.2 exp.variant_tools

Many-to-many relationship table linking variants to available MCP tools. Each variant can have multiple tools, and each tool can be available to multiple variants.

**Full DDL:** [postgres-schema-overview.sql](../infra/postgres-schema-overview.sql)

**Variant-Tool Relationship Example:**

```json
{
  "variant_id": "660e8400-e29b-41d4-a716-446655440001",
  "tool_id": "770e8400-e29b-41d4-a716-446655440002",
  "enabled": true,
  "priority": 0
}
```

**Tool Discovery Query Pattern:**

To discover tools available for a variant:

```sql
SELECT 
    t.id,
    t.name,
    t.description,
    t.server_name,
    t.tool_schema,
    t.capabilities,
    vt.priority,
    vt.enabled
FROM exp.mcp_tools t
INNER JOIN exp.variant_tools vt ON t.id = vt.tool_id
WHERE vt.variant_id = :variant_id
  AND vt.enabled = true
  AND t.status = 'active'
ORDER BY vt.priority ASC, t.name ASC;
```

**Relationships:**

- **Tools to Variants**: Many-to-many via `exp.variant_tools`
  - One tool can be available to multiple variants
  - One variant can have multiple tools
  - Tools are explicitly assigned to variants (not automatically inherited)

- **Tools to MCP Servers**: One-to-many via `server_name`
  - Multiple tools can come from the same MCP server
  - `server_name` references server configuration in `config/mcp_servers.json`
  - Tools are discovered from MCP servers and registered in database

**Status Values:**

| Status | Description |
|--------|-------------|
| `active` | Tool is available and can be assigned to variants |
| `deprecated` | Tool is no longer recommended but still supported |
| `unavailable` | Tool is temporarily unavailable (server down, etc.) |

**Tool Registration Flow:**

1. MCP server is configured in `config/mcp_servers.json`
2. MCP client discovers tools from server
3. Tools are registered in `exp.mcp_tools` table
4. Tools are assigned to variants via `exp.variant_tools`
5. Flow orchestrator includes tools in prompts for LLM access

**Tool Schema Storage:**

- Tool schemas are stored as JSONB for flexibility
- Supports full MCP tool schema format
- Enables efficient querying with GIN indexes
- Allows schema evolution without migrations

---

## 6. Offline Evaluation

### 6.1 exp.offline_replay_results

Stores offline evaluation results.

**Full DDL:** [postgres-schema-overview.sql](../infra/postgres-schema-overview.sql)

---

## 7. Useful Views

Pre-defined views for common query patterns: `exp.v_experiment_metrics`, `exp.v_active_experiments`.

**Full DDL:** [postgres-schema-overview.sql](../infra/postgres-schema-overview.sql)

---

## 8. Entity Relationships

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
            └──< exp.variants.config.mlflow_model.policy_version_id (FK reference)

exp.prompts
    │
    └──< exp.prompt_versions (1:N)
            │
            └──< exp.variants.config.prompt_config.prompt_version_id (FK reference)

exp.mcp_tools
    │
    └──< exp.variant_tools (many-to-many via variant_tools)
            │
            └──< exp.variants (many-to-many via variant_tools)
```

---

## Further Exploration

- **Understand experiment configuration** → [experiments.md](experiments.md)
- **See full schema file** → [../infra/postgres-schema-overview.sql](../infra/postgres-schema-overview.sql)
- **Learn about event logging** → [event-ingestion-service.md](event-ingestion-service.md)
- **Database migrations** → [../infra/migrations/README.md](../infra/migrations/README.md)
- **Prompt registry details** → See section 4 (Prompt Registry) above
- **MCP tool registry** → See section 5 (MCP Tool Registry) above

**See Also:**
- [architecture.md](architecture.md) - How data model fits into system architecture
- [assignment-service.md](assignment-service.md) - How assignments use these tables
- [experiments.md](experiments.md) - How variant configs use these tables
- [prompts-guide.md](prompts-guide.md) - Using prompt registry tables
- [mcp-integration.md](mcp-integration.md) - Using MCP tool registry tables
- [services/assignment-service/API_SPEC.md](../services/assignment-service/API_SPEC.md) - Assignment Service API
- [services/event-ingestion-service/API_SPEC.md](../services/event-ingestion-service/API_SPEC.md) - Event Ingestion API

---

## After Completing This Document

You will understand:
- The complete PostgreSQL schema (including ML and conversational AI tables)
- How experiments, variants, and assignments relate
- How events and metrics are stored
- How policies link to MLflow models (ML projects)
- How prompts link to prompt files (conversational AI projects)
- How MCP tools are registered and assigned to variants

**Next Step**: [experiments.md](experiments.md)

