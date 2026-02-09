# Conversational Assistant Example Project

**Purpose**  
This example demonstrates a complete conversational AI project using the experimentation platform. It shows how to create prompts, flows, and experiments for a meal planning assistant chatbot.

---

## Project Overview

This example implements a meal planning assistant that:
- Helps users plan meals based on preferences
- Collects dietary restrictions and preferences
- Suggests meal plans using LLM-powered prompts
- Tracks conversation metrics for experimentation

---

## Project Structure

```
conversational-assistant/
├── README.md                    # This file
├── prompts/                     # Prompt template files
│   ├── meal_planning_v1.txt    # Initial prompt version
│   └── meal_planning_v2.txt    # Improved prompt version
├── flows/                       # Conversation flow definitions
│   └── meal_planning_flow.yml   # Main conversation flow
└── config/                      # Configuration files
    ├── prompts.yml              # Prompt registry configuration
    └── experiments.yml          # Experiment configuration
```

---

## Quick Start

### Step 1: Review the Prompts

See `prompts/meal_planning_v1.txt` and `prompts/meal_planning_v2.txt` for example prompt templates.

**Key features:**
- Jinja2 template variables for dynamic content
- Clear instructions for the LLM
- Structured output format

### Step 2: Review the Flow

See `flows/meal_planning_flow.yml` for the conversation flow definition.

**Key features:**
- Multi-step data collection
- Validation rules
- Conditional branching
- Progress indicators

### Step 3: Review the Configuration

See `config/prompts.yml` for prompt registry configuration and `config/experiments.yml` for experiment setup.

**Key features:**
- Prompt version definitions
- Experiment variants with different prompt versions
- Flow configuration
- Model provider settings

---

## Implementation Steps

### 1. Register Prompts

Register the prompts in the database:

```sql
-- Create prompt record
INSERT INTO exp.prompts (name, description)
VALUES ('meal_planning_assistant', 'Assistant for helping users plan meals');

-- Register version 1
INSERT INTO exp.prompt_versions (
    prompt_id, version, file_path, model_provider, model_name,
    config_defaults, status
)
VALUES (
    (SELECT id FROM exp.prompts WHERE name = 'meal_planning_assistant'),
    1,
    'examples/conversational-assistant/prompts/meal_planning_v1.txt',
    'anthropic',
    'claude-sonnet-4.5',
    '{"temperature": 0.7, "max_tokens": 2048}'::jsonb,
    'active'
);

-- Register version 2
INSERT INTO exp.prompt_versions (
    prompt_id, version, file_path, model_provider, model_name,
    config_defaults, status
)
VALUES (
    (SELECT id FROM exp.prompts WHERE name = 'meal_planning_assistant'),
    2,
    'examples/conversational-assistant/prompts/meal_planning_v2.txt',
    'anthropic',
    'claude-sonnet-4.5',
    '{"temperature": 0.7, "max_tokens": 2048}'::jsonb,
    'active'
);
```

### 2. Load Flow Definition

Ensure the flow file `flows/meal_planning_flow.yml` is accessible to the Flow Orchestrator Service.

### 3. Configure Experiment

Use the experiment configuration from `config/experiments.yml`:

```yaml
experiments:
  - name: meal_planning_prompt_exp
    description: "Test different prompt templates for meal planning"
    unit_type: user
    status: active
    
    variants:
      - name: control
        allocation: 0.5
        config:
          execution_strategy: "prompt_template"
          prompt_config:
            prompt_version_id: "UUID_FROM_DB_V1"  # Replace with actual UUID
            model_provider: "anthropic"
            model_name: "claude-sonnet-4.5"
          flow_config:
            flow_id: "meal_planning_flow"
            initial_state: "welcome"
          params:
            temperature: 0.7
            max_tokens: 2048
      
      - name: improved_prompt
        allocation: 0.5
        config:
          execution_strategy: "prompt_template"
          prompt_config:
            prompt_version_id: "UUID_FROM_DB_V2"  # Replace with actual UUID
            model_provider: "anthropic"
            model_name: "claude-sonnet-4.5"
          flow_config:
            flow_id: "meal_planning_flow"
            initial_state: "welcome"
          params:
            temperature: 0.7
            max_tokens: 2048
```

### 4. Start Conversations

Use the Flow Orchestrator API to start conversations:

```bash
curl -X POST "https://api.example.com/api/v1/conversations" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "flow_id": "meal_planning_flow",
    "flow_version": "1.0.0",
    "user_id": "user-123",
    "context": {
      "experiment_id": "experiment-uuid",
      "variant_id": "variant-uuid"
    }
  }'
```

### 5. Process Messages

Process user messages through the Flow Orchestrator:

```bash
curl -X POST "https://api.example.com/api/v1/conversations/{session_id}/messages" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "I am vegetarian and love Italian food"
  }'
```

### 6. Log Events

Log conversation events to track metrics:

```bash
curl -X POST "https://api.example.com/api/v1/events" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "event_type": "conversation_started",
    "user_id": "user-123",
    "experiment_id": "experiment-uuid",
    "variant_id": "variant-uuid",
    "data": {
      "flow_id": "meal_planning_flow"
    }
  }'
```

---

## Key Concepts Demonstrated

### Prompt Versioning

This example shows:
- Multiple prompt versions (v1, v2)
- How to register versions in the database
- How to reference versions in experiments

### Conversation Flows

This example shows:
- Multi-step data collection
- State transitions based on user input
- Validation rules
- Progress tracking

### Experimentation

This example shows:
- A/B testing different prompt versions
- Using `execution_strategy: "prompt_template"`
- Configuring flow orchestration
- Tracking conversation metrics

---

## Monitoring

Monitor experiment results using Metabase dashboards:

- **Completion rate**: Percentage of conversations that complete successfully
- **Average turn count**: Average number of messages per conversation
- **Satisfaction scores**: User satisfaction ratings
- **Drop-off analysis**: Where users abandon conversations

**Related**: [../../analytics/metabase-models.md](../../analytics/metabase-models.md)

---

## Next Steps

1. **Customize prompts**: Modify prompt templates for your use case
2. **Adjust flows**: Update flow definitions to match your conversation needs
3. **Add variants**: Create more experiment variants to test different approaches
4. **Monitor results**: Set up Metabase dashboards to track metrics
5. **Iterate**: Use experiment results to improve prompts and flows

---

## Related Documentation

- **Prompt management**: [../../docs/prompts-guide.md](../../docs/prompts-guide.md)
- **Conversation flows**: [../../docs/conversation-flows.md](../../docs/conversation-flows.md)
- **Experiments**: [../../docs/experiments.md](../../docs/experiments.md)
- **Conversational AI route**: [../../docs/routes/conversational-ai-route.md](../../docs/routes/conversational-ai-route.md)
- **Flow Orchestrator API**: [../../services/flow-orchestrator/API_SPEC.md](../../services/flow-orchestrator/API_SPEC.md)
- **Prompt Service API**: [../../services/prompt-service/API_SPEC.md](../../services/prompt-service/API_SPEC.md)

---

## Notes

- This is an **example/template** project - adapt it to your needs
- Replace UUIDs in config files with actual database IDs
- Ensure prompt files are accessible to Prompt Service
- Ensure flow files are accessible to Flow Orchestrator
- Configure LLM API credentials for your environment
