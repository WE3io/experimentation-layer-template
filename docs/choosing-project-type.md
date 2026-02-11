# Choosing Your Project Type

**Purpose**  
This guide helps you decide whether to use the traditional ML approach (`execution_strategy: "mlflow_model"`) or the conversational AI approach (`execution_strategy: "prompt_template"`) for your experimentation project.

---

## Start Here If…

- **Starting a new project** → Read this guide first
- **Unsure which approach fits your use case** → Read this guide
- **Understanding execution strategies** → Read this guide
- **Already know your project type** → Skip to relevant documentation:
  - ML projects → [mlflow-guide.md](mlflow-guide.md)
  - Conversational AI → [prompts-guide.md](prompts-guide.md)

---

## Quick Decision Guide

| Your Project Involves | Recommended Type | Execution Strategy |
|------------------------|------------------|-------------------|
| Training custom models | Traditional ML | `mlflow_model` |
| Fine-tuning existing models | Traditional ML | `mlflow_model` |
| Offline evaluation on historical data | Traditional ML | `mlflow_model` |
| Chatbots or conversational interfaces | Conversational AI | `prompt_template` |
| LLM-powered assistants | Conversational AI | `prompt_template` |
| Prompt engineering experiments | Conversational AI | `prompt_template` |
| Structured dialogue systems | Conversational AI | `prompt_template` |
| Combining ML models with LLMs | Hybrid | `hybrid` |

---

## 1. Traditional ML Projects (`execution_strategy: "mlflow_model"`)

### When to Use

Use the ML-focused approach when your project involves:

- **Custom model training**: Training models from scratch on your data
- **Model fine-tuning**: Adapting pre-trained models to your domain
- **Offline evaluation**: Testing models on historical datasets before deployment
- **Model versioning**: Managing multiple versions of trained models
- **Feature engineering**: Creating and experimenting with input features
- **Model optimization**: Improving accuracy, latency, or resource usage

### Key Characteristics

| Aspect | Description |
|--------|-------------|
| **What varies** | Trained model weights and architectures |
| **Artefact type** | MLflow model version |
| **Registry** | MLflow Model Registry |
| **Evaluation** | Offline replay on historical data |
| **Metrics** | Accuracy, precision, recall, latency, resource usage |
| **Development cycle** | Train → Evaluate → Deploy → Monitor |

### Example Use Cases

**1. Meal Planning Model**
- Train a model to generate meal plans based on user preferences
- Experiment with different model architectures
- Evaluate on historical meal plan data
- Deploy best-performing model version

**2. Recommendation System**
- Fine-tune a recommendation model for your domain
- A/B test different model versions
- Measure click-through rates and engagement

**3. Ranking Algorithm**
- Train models to rank items (meals, products, etc.)
- Experiment with different ranking strategies
- Evaluate using offline metrics before live testing

### Configuration Example

See [config/experiments.example.yml](../config/experiments.example.yml) for complete format.

```yaml
variants:
  - name: control
    allocation: 0.5
    config:
      execution_strategy: "mlflow_model"
      mlflow_model:
        policy_version_id: "uuid"
        model_name: "planner_model"
      params: { temperature: 0.7 }
  - name: candidate_v2
    allocation: 0.5
    config:
      execution_strategy: "mlflow_model"
      mlflow_model:
        policy_version_id: "uuid"
        model_name: "planner_model"
      params: { temperature: 0.8 }
```

### Related Documentation

- **[mlflow-guide.md](mlflow-guide.md)** - Model registry, tracking, and versioning
- **[training-workflow.md](training-workflow.md)** - Dataset preparation and training process
- **[offline-evaluation.md](offline-evaluation.md)** - Replay evaluation methodology
- **[model-promotion.md](model-promotion.md)** - Moving models through candidate → production
- **[routes/training-route.md](routes/training-route.md)** - Training route quick start

---

## 2. Conversational AI Projects (`execution_strategy: "prompt_template"`)

### When to Use

Use the conversational AI approach when your project involves:

- **Chatbots**: Building conversational interfaces for users
- **LLM-powered assistants**: Using foundation models (Claude, GPT-4) without custom training
- **Prompt engineering**: Experimenting with different prompts and instructions
- **Conversation flows**: Managing multi-turn dialogues and state machines
- **Structured outputs**: Using LLMs to generate structured data (JSON, forms)
- **Rapid iteration**: Testing prompt changes without model retraining

### Key Characteristics

| Aspect | Description |
|--------|-------------|
| **What varies** | Prompts, flows, orchestration logic |
| **Artefact type** | Prompt template + flow config |
| **Registry** | Prompt Registry (PostgreSQL + Git) |
| **Evaluation** | Conversation replay + user testing |
| **Metrics** | Completion rate, satisfaction, turn count, drop-off analysis |
| **Development cycle** | Design prompt → Test → Deploy → Monitor |

### Example Use Cases

**1. Meal Planning Assistant**
- Chatbot that helps users plan meals through conversation
- Experiment with different prompt templates
- Test conversation flows (onboarding, data collection)
- Measure completion rates and user satisfaction

**2. Customer Support Bot**
- LLM-powered support assistant
- A/B test different response styles (formal vs. casual)
- Track resolution rates and user satisfaction

**3. Data Collection Assistant**
- Conversational interface for collecting structured data
- Experiment with different question phrasings
- Measure completion rates and data quality

### Configuration Example

See [config/experiments.example.yml](../config/experiments.example.yml) for complete format.

```yaml
variants:
  - name: control
    allocation: 0.5
    config:
      execution_strategy: "prompt_template"
      prompt_config:
        prompt_version_id: "uuid"
        model_provider: "anthropic"
        model_name: "claude-sonnet-4.5"
      flow_config:
        flow_id: "onboarding_v1"
        initial_state: "welcome"
      params:
        temperature: 0.7
        max_tokens: 2048
  
  - name: concise_prompt
    allocation: 0.5
    config:
      execution_strategy: "prompt_template"
      prompt_config:
        prompt_version_id: "880e8400-e29b-41d4-a716-446655440003"
        model_provider: "anthropic"
        model_name: "claude-sonnet-4.5"
      flow_config:
        flow_id: "onboarding_v1"
        initial_state: "welcome"
      params:
        temperature: 0.5
        max_tokens: 1024
```

### Related Documentation

### For Conversational AI Projects
- **[prompts-guide.md](prompts-guide.md)** - Prompt management and versioning
- **[conversation-flows.md](conversation-flows.md)** - Flow orchestration and state machines
- **[mcp-integration.md](mcp-integration.md)** - MCP setup and tool integration
- **[routes/conversational-ai-route.md](routes/conversational-ai-route.md)** - Conversational AI quick start guide
- **[examples/conversational-assistant/](../examples/conversational-assistant/)** - Complete example project

### For ML Projects
- **[mlflow-guide.md](mlflow-guide.md)** - Model registry and versioning
- **[training-workflow.md](training-workflow.md)** - Training and fine-tuning process
- **[routes/training-route.md](routes/training-route.md)** - ML project quick start guide

### Common to Both
- **[experiments.md](experiments.md)** - Experiment configuration (unified abstraction)
- **[architecture.md](architecture.md)** - System architecture overview
- **[data-model.md](data-model.md)** - Database schema (includes both ML and conversational AI tables)

---

## 3. Decision Criteria

### Choose ML (`mlflow_model`) If:

✅ You need to train custom models on your data  
✅ You have historical data for offline evaluation  
✅ Model accuracy/performance is the primary concern  
✅ You're experimenting with model architectures or features  
✅ You need fine-grained control over model behavior  
✅ Latency and resource optimization are important  

### Choose Conversational AI (`prompt_template`) If:

✅ You're building chatbots or conversational interfaces  
✅ You want to use foundation models (Claude, GPT-4) without training  
✅ You're experimenting with prompts and instructions  
✅ Rapid iteration without retraining is important  
✅ You need multi-turn conversation management  
✅ User experience and conversation quality are primary concerns  

### Choose Hybrid (`hybrid`) If:

✅ You need both ML models and LLM prompts in the same variant  
✅ ML models provide core logic, LLMs handle user interaction  
✅ You want to combine trained models with conversational interfaces  

---

## 4. Comparison Table

| Dimension | Traditional ML | Conversational AI |
|-----------|----------------|-------------------|
| **Primary focus** | Model training and optimization | Prompt engineering and flows |
| **Development time** | Weeks to months | Hours to days |
| **Iteration speed** | Slow (requires retraining) | Fast (prompt changes) |
| **Data requirements** | Large training datasets | Few-shot examples |
| **Infrastructure** | Training clusters, GPUs | API calls to LLM providers |
| **Evaluation** | Offline metrics on historical data | Conversation replay, user testing |
| **Cost model** | Compute-intensive training | Per-token API costs |
| **Best for** | Custom domain models | User-facing conversational interfaces |

---

## 5. Migration Between Types

### From ML to Conversational AI

If you have an ML project but want to add conversational interfaces:

1. Keep existing ML experiments running
2. Create new experiments with `execution_strategy: "prompt_template"`
3. Use ML model outputs as context for LLM prompts
4. Consider `hybrid` strategy if both are needed simultaneously

### From Conversational AI to ML

If you want to train custom models based on conversational AI insights:

1. Collect conversation data from LLM interactions
2. Use insights to design training datasets
3. Create new experiments with `execution_strategy: "mlflow_model"`
4. Train models on collected data

---

## 6. Examples by Use Case

### Use Case: Meal Planning

**ML Approach:**
- Train a model to generate meal plans
- Experiment with different architectures
- Evaluate on historical meal plan data
- Deploy best model version

**Conversational AI Approach:**
- Build a chatbot that helps users plan meals
- Experiment with different prompt templates
- Test conversation flows
- Measure completion rates

**Hybrid Approach:**
- Use ML model for core meal generation
- Use LLM for natural language interaction
- Combine both in same experiment

### Use Case: Recommendation System

**ML Approach:**
- Train recommendation models
- A/B test different algorithms
- Measure click-through rates

**Conversational AI Approach:**
- Build conversational recommender
- Experiment with question phrasings
- Measure engagement and satisfaction

---

## 7. Next Steps

Once you've chosen your project type:

**For ML Projects:**
1. Read [mlflow-guide.md](mlflow-guide.md) to understand model registry
2. Follow [routes/training-route.md](routes/training-route.md) for quick start
3. Review [experiments.md](experiments.md) for experiment configuration

**For Conversational AI Projects:**
1. Read [prompts-guide.md](prompts-guide.md)
2. Read [conversation-flows.md](conversation-flows.md)
3. Review [experiments.md](experiments.md) for experiment configuration

**For Both:**
- Review [experiments.md](experiments.md) for unified experiment concepts
- Check [config/experiments.example.yml](../../config/experiments.example.yml) for configuration examples

---

## Related Documentation

| Document | Purpose |
|----------|---------|
| [experiments.md](experiments.md) | Experiment concepts and configuration |
| [mlflow-guide.md](mlflow-guide.md) | ML model registry and versioning |
| [data-model.md](data-model.md) | Database schema (includes unified config structure) |
| [assignment-service.md](assignment-service.md) | How variant assignments work |
| [config/experiments.example.yml](../../config/experiments.example.yml) | Configuration examples |

---

## After Completing This Document

You will understand:
- When to use ML vs. conversational AI approaches
- What each execution strategy is best suited for
- How to configure experiments for each project type
- Where to find relevant documentation

**Next Step**: 
- **ML Projects** → [routes/training-route.md](routes/training-route.md) or [mlflow-guide.md](mlflow-guide.md)
- **Conversational AI Projects** → [routes/conversational-ai-route.md](routes/conversational-ai-route.md) or [prompts-guide.md](prompts-guide.md)

**See Also:**
- [architecture.md](architecture.md) - System overview showing both paths
- [experiments.md](experiments.md) - Unified experiment configuration
- [examples/README.md](../examples/README.md) - Example projects for both types
