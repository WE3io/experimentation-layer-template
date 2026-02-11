# Glossary

**Purpose**  
Canonical definitions for key terms used across the experimentation and model lifecycle documentation.

---

## Preferred Terms

| Term | Definition |
|------|------------|
| **conversational AI** | Projects using LLM-powered assistants, chatbots, or structured dialogue systems. Preferred over "chatbot" or "LLM assistant". |
| **prompt template** | A versioned prompt file in `/prompts/` with metadata in `exp.prompt_versions`. Use "prompt template" when referring to the artefact; "prompt" is acceptable for the content. |
| **conversation flow** | State machine definition for structured dialogues. Use "conversation flow" or "flow" when context is clear. |

---

## Execution Strategies

| Term | Definition |
|------|------------|
| **mlflow_model** | Execution strategy for traditional ML projects using trained models from MLflow Model Registry. |
| **prompt_template** | Execution strategy for conversational AI projects using versioned prompts and LLM providers. |
| **hybrid** | Execution strategy combining both ML models and prompt templates in the same variant. |

---

## Services

| Term | Definition |
|------|------------|
| **EAS** | Experiment Assignment Service. Assigns units to variants and returns config. |
| **EIS** | Event Ingestion Service. Records events with experiment context. |
| **Prompt Service** | Retrieves prompt versions by ID; loads content from `/prompts/`. |
| **Flow Orchestrator** | Manages conversation flow state machines; sessions stored in Redis. |

---

## Experimentation

| Term | Definition |
|------|------------|
| **unit** | Entity assigned to a variant: `user`, `household`, or `session`. |
| **unit_type** | The type of unit for an experiment: `user`, `household`, or `session`. |
| **variant** | A configuration within an experiment (e.g. control, treatment) with allocation and config. |
| **assignment** | Deterministic mapping of (experiment_id, unit_id) to a variant. |
| **allocation** | Decimal 0.0–1.0 representing percentage of traffic for a variant. |

---

## Artefacts

| Term | Definition |
|------|------------|
| **policy_version_id** | Reference to `exp.policy_versions`; links variant to MLflow model. |
| **prompt_version_id** | Reference to `exp.prompt_versions`; links variant to prompt template. |
| **flow_id** | Identifier for a conversation flow definition in `/flows/`. |
