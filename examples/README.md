# Example Projects

This directory contains complete, end-to-end example projects demonstrating how to use the experimentation platform for different project types.

---

## Available Examples

### [Conversational Assistant](./conversational-assistant/)

A complete conversational AI project demonstrating:
- Prompt template creation and versioning
- Conversation flow definition
- Experiment configuration for A/B testing prompts
- Integration with Prompt Service and Flow Orchestrator

**Use this example if:** You're building chatbots, LLM-powered assistants, or structured dialogue systems.

**Quick Start:** See [conversational-assistant/README.md](./conversational-assistant/README.md)

---

## Project Types

### Conversational AI Projects

For projects using prompts, flows, and LLM providers:

- **Execution Strategy**: `prompt_template`
- **Key Components**: Prompt Service, Flow Orchestrator, LLM APIs
- **Example**: [conversational-assistant](./conversational-assistant/)

**Related Documentation:**
- [Choosing Project Type](../docs/choosing-project-type.md)
- [Conversational AI Route](../docs/routes/conversational-ai-route.md)
- [Prompts Guide](../docs/prompts-guide.md)
- [Conversation Flows Guide](../docs/conversation-flows.md)

### ML Projects

For projects using trained models and MLflow:

- **Execution Strategy**: `mlflow_model`
- **Key Components**: MLflow, Training Pipelines, Model Registry
- **Example**: See [training/](../training/) directory for ML project patterns

**Related Documentation:**
- [Choosing Project Type](../docs/choosing-project-type.md)
- [Training Route](../docs/routes/training-route.md)
- [MLflow Guide](../docs/mlflow-guide.md)

---

## Using Examples

### Step 1: Choose Your Example

Select the example that matches your project type:
- **Conversational AI** → `conversational-assistant/`
- **ML Projects** → See `training/` directory

### Step 2: Review the Structure

Each example includes:
- **README.md**: Project overview and quick start guide
- **Configuration files**: Example configs for prompts, flows, experiments
- **Source files**: Example prompts, flows, or training code

### Step 3: Adapt to Your Needs

- Copy and modify example files
- Replace placeholder values (UUIDs, file paths, etc.)
- Customize for your specific use case
- Follow the implementation steps in each README

### Step 4: Register and Deploy

- Register prompts/flows/models in the database
- Load configurations into the system
- Start running experiments
- Monitor results via Metabase

---

## Notes

- Examples are **templates** - adapt them to your needs
- Replace placeholder UUIDs with actual database IDs
- Ensure file paths are correct for your environment
- Configure API credentials and service endpoints
- Examples demonstrate patterns, not production-ready code

---

## Contributing Examples

To add a new example project:

1. Create a new directory under `/examples/`
2. Include a comprehensive README.md
3. Provide example configuration files
4. Link to relevant documentation
5. Follow existing example structure

---

## Related Documentation

- **Main Documentation**: [../docs/README.md](../docs/README.md)
- **Architecture**: [../docs/architecture.md](../docs/architecture.md)
- **Choosing Project Type**: [../docs/choosing-project-type.md](../docs/choosing-project-type.md)
