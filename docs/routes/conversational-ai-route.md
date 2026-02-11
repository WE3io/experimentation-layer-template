# Conversational AI Route

**Purpose**  
This route guides developers who want to build conversational AI projects (chatbots, LLM-powered assistants, structured dialogue systems) using the experimentation platform.

---

## Prerequisites

- [architecture.md](../architecture.md) - System overview
- [choosing-project-type.md](../choosing-project-type.md) - Confirm conversational AI path
- [data-model.md](../data-model.md) - Schema (sections 1–2, 4–5)

---

## Route Overview

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│ choosing-       │ ──► │ prompts-guide.md │ ──► │ conversation-   │
│ project-type.md │     │                 │     │ flows.md        │
└─────────────────┘     └─────────────────┘     └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
   Decision              Prompt Service          Flow Orchestrator
   Guide                API + Config            API + Examples
         │
         ▼
┌─────────────────┐
│ experiments.md  │
│ (with prompt    │
│  template       │
│  strategy)      │
└─────────────────┘
```

---

## Quick Start: Your First Conversational AI Project

Follow these steps to get a conversational AI project running experiments within hours:

### Step 1: Choose Your Project Type
**Read**: [../choosing-project-type.md](../choosing-project-type.md)

Confirm you're building a conversational AI project (chatbot, assistant, structured dialogue).

**After**: You understand why `execution_strategy: "prompt_template"` is right for your project.

### Step 2: Create Your First Prompt
**Read**: [../prompts-guide.md](../prompts-guide.md) (sections 1-3)

Create a prompt file in `/prompts/` directory:

```bash
# Create prompt file
cat > prompts/my_assistant_v1.txt << 'EOF'
You are a helpful assistant for {{ user_name }}.

Your goal is to help users with their questions in a friendly and concise manner.

When helping users:
- Be clear and direct
- Ask clarifying questions when needed
- Provide actionable advice
EOF
```

**After**: You have a prompt file ready to register.

### Step 3: Register Your Prompt
**Read**: [../prompts-guide.md](../prompts-guide.md) (section 4)

Register the prompt in the database:

```sql
-- Create prompt record
INSERT INTO exp.prompts (name, description)
VALUES ('my_assistant', 'Helpful assistant for user questions');

-- Create prompt version
INSERT INTO exp.prompt_versions (
    prompt_id, 
    version, 
    file_path,
    model_provider,
    model_name,
    config_defaults,
    status
)
VALUES (
    (SELECT id FROM exp.prompts WHERE name = 'my_assistant'),
    1,
    'prompts/my_assistant_v1.txt',
    'anthropic',
    'claude-sonnet-4.5',
    '{"temperature": 0.7, "max_tokens": 2048}'::jsonb,
    'active'
);
```

**After**: Your prompt is registered and ready to use in experiments.

### Step 4: (Optional) Create a Conversation Flow
**Read**: [../conversation-flows.md](../conversation-flows.md) (sections 1-3)

If you need structured multi-turn conversations, create a flow:

```bash
# Create flow file
cat > flows/my_onboarding.yml << 'EOF'
flow:
  name: my_onboarding
  version: "1.0.0"
  description: "Simple onboarding flow"
  initial_state: welcome
  
  states:
    welcome:
      type: question
      message: "Welcome! What can I help you with?"
    complete:
      type: end
      message: "Thank you!"
  
  transitions:
    - from: welcome
      to: complete
      condition:
        type: always
EOF
```

**After**: You have a flow definition ready (if needed).

### Step 5: Configure Your First Experiment
**Read**: [../experiments.md](../experiments.md) (section 4.4)

Create an experiment configuration. See [config/experiments.example.yml](../../config/experiments.example.yml) for complete format.

```yaml
experiments:
  - name: assistant_prompt_exp
    unit_type: user
    status: active
    variants:
      - name: control
        allocation: 0.5
        config:
          execution_strategy: "prompt_template"
          prompt_config:
            prompt_version_id: "YOUR_PROMPT_VERSION_UUID"  # From Step 3
            model_provider: "anthropic"
            model_name: "claude-sonnet-4.5"
          flow_config: { flow_id: "my_onboarding", initial_state: "welcome" }
          params: { temperature: 0.7, max_tokens: 2048 }
      - name: improved_prompt
        allocation: 0.5
        config:
          execution_strategy: "prompt_template"
          prompt_config:
            prompt_version_id: "ANOTHER_PROMPT_VERSION_UUID"
            model_provider: "anthropic"
            model_name: "claude-sonnet-4.5"
          params: { temperature: 0.7, max_tokens: 2048 }
```

**After**: Your experiment is configured and ready to run.

### Step 6: Start Your First A/B Test

1. **Load experiment configuration** into the system
2. **Call Assignment Service** to get variant assignments
3. **Retrieve prompts** from Prompt Service using `prompt_version_id`
4. **Execute flows** (if configured) using Flow Orchestrator
5. **Call LLM API** with prompt template and conversation context
6. **Log conversation events** to Event Ingestion Service

**After**: Your conversational AI project is running experiments!

---

## Documents in This Route

### 1. Start Here: [../choosing-project-type.md](../choosing-project-type.md)
**Learn**: Decision guide for choosing between ML and conversational AI approaches

**After**: You understand why conversational AI is right for your project.

### 2. Next: [../prompts-guide.md](../prompts-guide.md)
**Learn**: How to create, version, and manage prompts

**After**: You can create prompt templates and register them in the system.

### 3. Then: [../conversation-flows.md](../conversation-flows.md)
**Learn**: How to create conversation flows as state machines

**After**: You can design structured multi-turn conversations (if needed).

### 4. Then: [../experiments.md](../experiments.md)
**Learn**: How to configure experiments with `execution_strategy: "prompt_template"`

**After**: You can create experiments that test different prompts and flows.

### 5. Then: [../../services/prompt-service/API_SPEC.md](../../services/prompt-service/API_SPEC.md)
**Learn**: How to retrieve prompts via Prompt Service API

**After**: You can integrate Prompt Service into your application.

### 6. Then: [../../services/flow-orchestrator/API_SPEC.md](../../services/flow-orchestrator/API_SPEC.md)
**Learn**: How to manage conversation sessions via Flow Orchestrator API

**After**: You can integrate Flow Orchestrator into your application (if using flows).

### 7. Finally: [../event-ingestion-service.md](../event-ingestion-service.md)
**Learn**: How to log conversation events with experiment context

**After**: You can track conversation metrics and analyze experiment results.

---

## Supporting Documents

| Document | Purpose |
|----------|---------|
| [../architecture.md](../architecture.md) | System overview including conversational AI components |
| [../data-model.md](../data-model.md) | Schema for prompts, prompt_versions, flows |
| [../../config/prompts.example.yml](../../config/prompts.example.yml) | Example prompt configuration |
| [../../config/flows.example.yml](../../config/flows.example.yml) | Example flow configuration (if exists) |
| [../../prompts/README.md](../../prompts/README.md) | Prompt file structure and examples |
| [../../flows/README.md](../../flows/README.md) | Flow file structure and examples |
| [../../analytics/metabase-models.md](../../analytics/metabase-models.md) | Monitoring conversation metrics |
| [../mcp-integration.md](../mcp-integration.md) | MCP integration for external tools |

---

## Route Outcomes

After completing this route, you will be able to:

1. ✓ Create and version prompt templates
2. ✓ Design conversation flows (if needed)
3. ✓ Register prompts and flows in the system
4. ✓ Configure experiments with `execution_strategy: "prompt_template"`
5. ✓ Retrieve prompts via Prompt Service API
6. ✓ Manage conversation sessions via Flow Orchestrator API (if using flows)
7. ✓ Log conversation events with experiment context
8. ✓ Run A/B tests comparing different prompts/flows
9. ✓ Monitor conversation metrics in Metabase

---

## Common Workflows

### Workflow 1: Simple Prompt-Only Project

For projects that only need prompt templates (no structured flows):

1. Create prompt files in `/prompts/`
2. Register prompts in database
3. Configure experiments with `prompt_config` only (no `flow_config`)
4. Retrieve prompts via Prompt Service
5. Call LLM API directly with prompt content

**Documents**: [prompts-guide.md](../prompts-guide.md), [experiments.md](../experiments.md)

### Workflow 2: Structured Conversation Project

For projects needing multi-turn structured dialogues:

1. Create prompt files in `/prompts/`
2. Create flow definitions in `/flows/`
3. Register prompts and flows
4. Configure experiments with both `prompt_config` and `flow_config`
5. Use Flow Orchestrator to manage conversation state
6. Retrieve prompts via Prompt Service
7. Call LLM API with prompt and flow context

**Documents**: [prompts-guide.md](../prompts-guide.md), [conversation-flows.md](../conversation-flows.md), [experiments.md](../experiments.md)

### Workflow 3: Prompt A/B Testing

For testing different prompt versions:

1. Create multiple prompt versions (v1, v2, v3)
2. Register all versions in database
3. Create experiment with variants referencing different `prompt_version_id`
4. Monitor conversation metrics (completion rate, satisfaction, etc.)
5. Promote winning prompt version

**Documents**: [prompts-guide.md](../prompts-guide.md), [experiments.md](../experiments.md), [../../analytics/metabase-models.md](../../analytics/metabase-models.md)

---

## Branching Points

| If you want to... | Go to... |
|-------------------|----------|
| Understand the full system architecture | [../architecture.md](../architecture.md) |
| Learn about ML projects instead | [training-route.md](training-route.md) |
| Monitor conversation metrics | [analytics-route.md](analytics-route.md) |
| Integrate external tools via MCP | [../mcp-integration.md](../mcp-integration.md) |
| Understand event logging | [event-logging-route.md](event-logging-route.md) |
| Return to main docs | [../README.md](../README.md) |

---

## Next Steps

1. **Complete the Quick Start** above to get your first project running
2. **Read the full guides** for deeper understanding
3. **Explore example prompts and flows** in `/prompts/` and `/flows/` directories
4. **Set up monitoring** to track conversation metrics
5. **Iterate and improve** your prompts based on experiment results

**Ready to start?** Begin with [../choosing-project-type.md](../choosing-project-type.md)
