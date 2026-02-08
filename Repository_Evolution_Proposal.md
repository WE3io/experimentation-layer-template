# Repository Evolution Proposal

*Extending ML Experimentation Platform for Conversational AI*

February 2026

## Executive Summary

This proposal outlines a strategy to evolve the existing ML experimentation platform into a unified template that supports both traditional machine learning projects (model training, fine-tuning, offline evaluation) and modern conversational AI projects (chatbots, LLM-powered assistants, structured dialogue systems).

**Key Objectives:**

1. **Preserve existing capabilities:** Maintain full support for custom model training workflows
2. **Add conversational AI support:** Enable experimentation with prompts, flows, and foundation models
3. **Unified abstraction:** Create a single framework that works for both use cases
4. **Rapid project setup:** Enable teams to start either project type within hours, not days

## 1. Current State Analysis

### 1.1 Existing Strengths

The current repository excels at:

- **Experimentation framework:** Robust A/B testing with deterministic assignment, variant allocation, and statistical validity
- **Event logging architecture:** Comprehensive event capture with experiment context, enabling rich analytics
- **Model lifecycle management:** MLflow integration for versioning, tracking, and promotion workflows
- **Analytics infrastructure:** Metabase dashboards, PostgreSQL aggregation, and metrics pipelines
- **Clear documentation:** Well-structured docs with multiple learning paths and detailed specifications

### 1.2 Gaps for Conversational AI

To support chatbot/conversational AI projects, the repository needs:

- **Prompt template management:** Version control and experimentation for prompts instead of trained models
- **Conversation flow definitions:** State machines, decision trees, and dialogue orchestration patterns
- **MCP integration patterns:** Standardised tool/data source connections for LLM applications
- **Conversation-specific metrics:** Completion rates, drop-off analysis, turn counts, user satisfaction
- **Foundation model orchestration:** Patterns for using pre-trained LLMs (Claude, GPT-4) without custom training
- **Structured output validation:** JSON Schema enforcement for form-like interactions

## 2. Unified Abstraction Design

The key insight is that both ML and conversational AI projects share the same experimentation backbone but differ in what they're experimenting on. We introduce a flexible 'variant configuration' system that abstracts over these differences.

### 2.1 Core Abstraction: The Variant Config

Instead of hardcoding policy_version_id references to MLflow, we generalise the variant config to support multiple 'execution strategies':

| Dimension | Traditional ML | Conversational AI |
|-----------|----------------|-------------------|
| **What varies** | Trained model weights | Prompts, flows, orchestration logic |
| **Artefact type** | MLflow model version | Prompt template + flow config |
| **Registry** | MLflow Model Registry | Prompt Registry (PostgreSQL + Git) |
| **Evaluation** | Offline replay on historical data | Conversation replay + user testing |
| **Metrics** | Accuracy, latency, resource usage | Completion rate, satisfaction, turn count |

**Proposed unified schema:**

```json
{
  "execution_strategy": "mlflow_model" | "prompt_template" | "hybrid",
  "mlflow_model": {
    "policy_version_id": "uuid-v1",
    "model_name": "planner_model"
  },
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

## 3. New Components for Conversational AI

### 3.1 Prompt Registry (New)

A versioned prompt management system analogous to MLflow for models:

- **Database schema:** exp.prompts, exp.prompt_versions tables
- **Git integration:** Prompts stored in /prompts/ directory with version control
- **Template syntax:** Support Jinja2/Mustache for variable substitution
- **Metadata tracking:** Token counts, validation status, performance metrics

**Example prompt version config:**

```yaml
prompts:
  - name: meal_planning_assistant
    versions:
      - version: 1
        description: "Initial version with basic planning"
        file: prompts/meal_planning_v1.txt
        model_provider: anthropic
        model_name: claude-sonnet-4.5
        status: active
        params:
          temperature: 0.7
          max_tokens: 2048
```

### 3.2 Conversation Flow Engine (New)

State machine and flow orchestration for structured dialogues:

- **Flow definitions:** YAML-based state machines with transitions, conditions, actions
- **Session management:** Redis-backed conversation state with expiry
- **Context tracking:** Maintain conversation history and collected data
- **Validation hooks:** Input validation, format checking, business rules

### 3.3 MCP Integration Layer (New)

Standardised tool and data source connections:

- **Server configuration:** config/mcp_servers.json for tool discovery
- **Client library:** Python/Node MCP client wrappers
- **Tool registry:** Database tracking of available tools per variant
- **Example servers:** Pre-configured database, API, file system connectors

### 3.4 Conversation Analytics (Extended)

New Metabase models and event types for chatbot metrics:

- **Event types:** conversation_started, message_sent, flow_completed, user_dropped_off
- **Metrics:** Completion rate by flow, average turn count, time to completion, satisfaction scores
- **Dashboards:** Funnel analysis, drop-off heatmaps, variant comparison

## 4. Proposed Repository Structure

```
/
├── README.md                           ← Updated with project type selector
├── docs/
│   ├── architecture.md                 ← Extended with conversational AI
│   ├── choosing-project-type.md        ← NEW: Decision guide
│   ├── experiments.md                  ← Updated for unified abstraction
│   ├── prompts-guide.md                ← NEW: Prompt management
│   ├── conversation-flows.md           ← NEW: Flow orchestration
│   ├── mcp-integration.md              ← NEW: MCP setup
│   ├── mlflow-guide.md                 ← Existing, for ML projects
│   └── routes/
│       ├── ml-route.md                 ← Existing routes renamed
│       └── conversational-ai-route.md  ← NEW: Chatbot quick start
├── config/
│   ├── experiments.example.yml         ← Extended examples
│   ├── policies.example.yml            ← For ML projects
│   ├── prompts.example.yml             ← NEW: For conversational AI
│   ├── flows.example.yml               ← NEW: Conversation flows
│   └── mcp_servers.example.json        ← NEW: MCP configuration
├── services/
│   ├── assignment-service/             ← Existing, updated
│   ├── event-ingestion-service/        ← Existing, extended events
│   ├── prompt-service/                 ← NEW: Prompt delivery
│   └── flow-orchestrator/              ← NEW: Conversation management
├── prompts/                             ← NEW: Versioned prompts directory
│   ├── meal_planning_v1.txt
│   ├── meal_planning_v2.txt
│   └── customer_support_v1.txt
├── flows/                               ← NEW: Flow definitions
│   ├── onboarding_flow.yml
│   └── data_collection_flow.yml
├── training/                            ← Existing, for ML projects
├── pipelines/
│   ├── training-data.md                ← Existing, for ML
│   └── conversation-replay.md          ← NEW: For chatbot evaluation
├── analytics/
│   ├── metabase-models.md              ← Extended with chatbot metrics
│   └── conversation-analytics.sql      ← NEW: Chatbot queries
└── examples/                            ← NEW: Full project examples
    ├── ml-recommendation-system/
    └── conversational-assistant/
```

## 5. Implementation Roadmap

### Phase 1: Core Abstractions (Week 1-2)

- Update variants.config schema to support execution_strategy field
- Extend assignment service to handle both MLflow and prompt configs
- Create unified experiment configuration validator
- Update documentation with project type decision guide

### Phase 2: Prompt Management (Week 3-4)

- Implement exp.prompts and exp.prompt_versions database schema
- Build prompt service API for version retrieval
- Create /prompts/ directory structure with examples
- Add prompts.example.yml configuration

### Phase 3: Conversation Flows (Week 5-6)

- Design flow definition YAML schema
- Implement flow orchestrator service with state machine logic
- Add Redis session management
- Create example flows (onboarding, data collection, support)

### Phase 4: MCP Integration (Week 7-8)

- Add MCP client libraries (Python and Node.js)
- Create mcp_servers.example.json with common integrations
- Build tool registry for tracking available capabilities
- Document MCP integration patterns

### Phase 5: Analytics & Events (Week 9-10)

- Extend event schema with conversation-specific event types
- Create Metabase models for chatbot metrics
- Build conversation replay pipeline
- Add SQL queries for funnel analysis and drop-off detection

### Phase 6: Documentation & Examples (Week 11-12)

- Write complete conversational-ai-route.md guide
- Create end-to-end example projects in /examples/
- Update README with clear project type selection
- Record video walkthroughs for both project types

## 6. Migration Guide for Existing Projects

Existing ML projects using the current repository structure will continue to work with minimal changes. The migration path is:

### For Existing ML Projects:

1. **Add execution_strategy field:** Set to "mlflow_model" in variant configs
2. **Wrap existing config:** Move policy_version_id into mlflow_model object
3. **Update service calls:** Assignment service maintains backward compatibility

**Example transformation:**

```yaml
# Before (still supported)
config:
  policy_version_id: "uuid-v1"
  params:
    temperature: 0.7

# After (recommended)
config:
  execution_strategy: "mlflow_model"
  mlflow_model:
    policy_version_id: "uuid-v1"
  params:
    temperature: 0.7
```

### Starting a New Conversational AI Project:

1. **Follow conversational-ai-route.md:** Step-by-step quickstart guide
2. **Copy example configs:** Start with prompts.example.yml and flows.example.yml
3. **Define conversation flows:** Create YAML state machines in /flows/
4. **Version prompts:** Store prompts in /prompts/ with version tracking
5. **Configure experiments:** Use execution_strategy: "prompt_template"

## 7. Benefits Analysis

### 7.1 For ML Teams

- **No disruption:** Existing workflows continue unchanged
- **Optional adoption:** Can integrate conversational interfaces gradually
- **Unified experimentation:** Same framework for testing model variants and user interfaces

### 7.2 For Conversational AI Teams

- **Battle-tested infrastructure:** Proven experimentation and analytics patterns
- **Rapid setup:** Production-ready in hours, not weeks
- **Best practices built-in:** Statistical validity, version control, rollback safety
- **Foundation model focus:** Designed for prompt engineering, not custom training

### 7.3 For the Organisation

- **Unified tooling:** Single template for all AI/ML experimentation
- **Knowledge transfer:** Teams can move between project types easily
- **Reduced maintenance:** One platform instead of separate systems
- **Faster innovation:** New projects start with production-grade infrastructure

## 8. Success Metrics

We will measure the success of this evolution through:

### Setup Speed
- Target: New conversational AI project running experiments within 4 hours
- Metric: Time from repository clone to first A/B test in production

### Adoption Rate
- Target: 3+ teams using the repository for chatbot projects within 6 months
- Metric: Number of active projects in both categories

### Documentation Quality
- Target: Developers can choose and start projects without external help
- Metric: Support tickets and questions in first 30 days

### Backward Compatibility
- Target: Zero breaking changes for existing ML projects
- Metric: All existing experiments continue running after upgrade

## 9. Risks & Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| Scope creep during implementation | Timeline extends beyond 12 weeks | Strict phase gating, MVP features only |
| Complexity confuses users | Low adoption due to steep learning curve | Clear project type selector, separate routes in docs |
| Breaking changes for existing projects | Production ML systems fail after upgrade | Maintain backward compatibility, gradual migration |
| Poor documentation quality | Teams cannot self-serve, require constant support | User testing with 3+ external developers before release |

## 10. Conclusion & Next Steps

This proposal outlines a clear path to evolve the ML experimentation platform into a unified template supporting both traditional ML and modern conversational AI projects. The approach preserves existing capabilities whilst adding substantial new value for teams building chatbots and LLM-powered assistants.

**The key advantages of this approach:**

- **Unified experimentation:** One framework for all AI/ML projects
- **Zero disruption:** Existing ML projects continue without changes
- **Rapid value:** New chatbot projects operational within hours
- **Production-ready:** Battle-tested patterns from existing deployments
- **Future-proof:** Extensible architecture for emerging AI patterns

**Recommended Next Steps:**

1. **Approve proposal and allocate resources:** 2 engineers for 12 weeks
2. **Begin Phase 1 implementation:** Core abstractions and schema updates
3. **Identify pilot conversational AI project:** Real-world validation during development
4. **Schedule milestone reviews:** Bi-weekly demos and progress assessment

---

*Proposal prepared: February 2026*
