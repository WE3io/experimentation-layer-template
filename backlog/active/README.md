# Repository Evolution Backlog

**Purpose**  
This backlog tracks work items for implementing the Repository Evolution Proposal, extending the ML experimentation platform to support conversational AI projects alongside traditional ML projects.

**Source Document:** [Repository_Evolution_Proposal.md](../Repository_Evolution_Proposal.md)

---

## Overview

This backlog contains 40 work items organized across 6 implementation phases plus cross-cutting concerns. Each work item follows the work-item-designer format with clear outcomes, constraints, acceptance checks, and non-goals.

---

## Phase Summary

| Phase | Focus | Items | Duration |
|-------|-------|-------|----------|
| **Phase 1** | Core Abstractions | 7 | Week 1-2 |
| **Phase 2** | Prompt Management | 6 | Week 3-4 |
| **Phase 3** | Conversation Flows | 5 | Week 5-6 |
| **Phase 4** | MCP Integration | 5 | Week 7-8 |
| **Phase 5** | Analytics & Events | 6 | Week 9-10 |
| **Phase 6** | Documentation & Examples | 7 | Week 11-12 |
| **Cross-cutting** | Migration & Compatibility | 4 | Throughout |

**Total: 40 work items**

---

## Dependency Graph

```
Phase 1: Core Abstractions
├── variant-config-schema-docs → variant-config-migration
├── variant-config-migration → assignment-service-api-update
├── variant-config-migration → assignment-service-design-update
└── assignment-service-api-update → config-validator

Phase 2: Prompt Management
├── prompt-registry-schema-design → prompt-registry-migration
├── prompt-registry-migration → prompt-service-api-spec
└── prompt-registry-migration → prompt-service-design

Phase 3: Conversation Flows
└── flow-yaml-schema-design → flow-orchestrator-api-spec
    └── flow-yaml-schema-design → flow-orchestrator-design

Phase 4: MCP Integration
└── tool-registry-schema-design → tool-registry-migration

Phase 5: Analytics & Events
└── event-schema-extension-docs → event-schema-migration
    └── event-schema-migration → event-ingestion-api-update

Cross-cutting
└── All phases → migration-guide
```

---

## Work Items by Phase

### Phase 1: Core Abstractions

1. [phase1-variant-config-schema-docs.md](phase1-variant-config-schema-docs.md) - Extend variant config schema documentation
2. [phase1-variant-config-migration.md](phase1-variant-config-migration.md) - Create database migration for variant config
3. [phase1-assignment-service-api-update.md](phase1-assignment-service-api-update.md) - Update Assignment Service API spec
4. [phase1-assignment-service-design-update.md](phase1-assignment-service-design-update.md) - Update Assignment Service design
5. [phase1-config-validator.md](phase1-config-validator.md) - Create unified experiment configuration validator
6. [phase1-experiments-example-update.md](phase1-experiments-example-update.md) - Update experiments.example.yml
7. [phase1-project-type-decision-guide.md](phase1-project-type-decision-guide.md) - Add project type decision guide

### Phase 2: Prompt Management

1. [phase2-prompt-registry-schema-design.md](phase2-prompt-registry-schema-design.md) - Design prompt registry database schema
2. [phase2-prompt-registry-migration.md](phase2-prompt-registry-migration.md) - Create database migration for prompt registry
3. [phase2-prompt-service-api-spec.md](phase2-prompt-service-api-spec.md) - Create Prompt Service API specification
4. [phase2-prompt-service-design.md](phase2-prompt-service-design.md) - Create Prompt Service design
5. [phase2-prompts-directory-examples.md](phase2-prompts-directory-examples.md) - Create /prompts/ directory with example prompts
6. [phase2-prompts-example-config.md](phase2-prompts-example-config.md) - Add prompts.example.yml configuration

### Phase 3: Conversation Flows

1. [phase3-flow-yaml-schema-design.md](phase3-flow-yaml-schema-design.md) - Design flow definition YAML schema
2. [phase3-flow-orchestrator-api-spec.md](phase3-flow-orchestrator-api-spec.md) - Create Flow Orchestrator service API spec
3. [phase3-flow-orchestrator-design.md](phase3-flow-orchestrator-design.md) - Create Flow Orchestrator service design
4. [phase3-redis-session-management.md](phase3-redis-session-management.md) - Design Redis session management
5. [phase3-example-flow-definitions.md](phase3-example-flow-definitions.md) - Create example flow definitions

### Phase 4: MCP Integration

1. [phase4-tool-registry-schema-design.md](phase4-tool-registry-schema-design.md) - Design tool registry database schema
2. [phase4-tool-registry-migration.md](phase4-tool-registry-migration.md) - Create database migration for tool registry
3. [phase4-mcp-client-wrappers-spec.md](phase4-mcp-client-wrappers-spec.md) - Create MCP client library wrappers specification
4. [phase4-mcp-servers-example-config.md](phase4-mcp-servers-example-config.md) - Create mcp_servers.example.json configuration
5. [phase4-mcp-integration-docs.md](phase4-mcp-integration-docs.md) - Document MCP integration patterns

### Phase 5: Analytics & Events

1. [phase5-event-schema-extension-docs.md](phase5-event-schema-extension-docs.md) - Extend event schema documentation
2. [phase5-event-schema-migration.md](phase5-event-schema-migration.md) - Create database migration for event extensions
3. [phase5-event-ingestion-api-update.md](phase5-event-ingestion-api-update.md) - Update Event Ingestion Service API spec
4. [phase5-metabase-chatbot-models.md](phase5-metabase-chatbot-models.md) - Create Metabase models for chatbot metrics
5. [phase5-conversation-replay-pipeline.md](phase5-conversation-replay-pipeline.md) - Create conversation replay pipeline specification
6. [phase5-conversation-analytics-sql.md](phase5-conversation-analytics-sql.md) - Add SQL queries for funnel analysis

### Phase 6: Documentation & Examples

1. [phase6-architecture-docs-update.md](phase6-architecture-docs-update.md) - Update architecture.md with conversational AI
2. [phase6-experiments-docs-update.md](phase6-experiments-docs-update.md) - Update experiments.md for unified abstraction
3. [phase6-prompts-guide.md](phase6-prompts-guide.md) - Create prompts-guide.md
4. [phase6-conversation-flows-guide.md](phase6-conversation-flows-guide.md) - Create conversation-flows.md
5. [phase6-conversational-ai-route.md](phase6-conversational-ai-route.md) - Write conversational-ai-route.md guide
6. [phase6-example-projects.md](phase6-example-projects.md) - Create end-to-end example projects
7. [phase6-readme-update.md](phase6-readme-update.md) - Update README with project type selector

### Cross-Cutting Items

1. [crosscut-migration-guide.md](crosscut-migration-guide.md) - Create migration guide documentation
2. [crosscut-backward-compat-testing.md](crosscut-backward-compat-testing.md) - Design backward compatibility testing strategy
3. [crosscut-route-docs-update.md](crosscut-route-docs-update.md) - Update existing route documentation
4. [crosscut-data-model-update.md](crosscut-data-model-update.md) - Update data-model.md with new tables

---

## Documentation Principles Alignment

Align documentation with documentation-principles (position reader, durable contracts, link over duplicate, value vs maintenance). Suggested order: 1 → 8 → 5 → 3 → 2 → 4 → 6 → 7.

**Execution plan**: [DOCPRINCIPLES_EXECUTION_PLAN.md](DOCPRINCIPLES_EXECUTION_PLAN.md) – how to run these with the implementation-executor skill (one item per invocation).

1. [docprinciples-fix-stale-refs.md](docprinciples-fix-stale-refs.md) - Remove outdated phase references from choosing-project-type.md
2. [docprinciples-schema-deduplication.md](docprinciples-schema-deduplication.md) - Link data-model to canonical schema; remove inline DDL
3. [docprinciples-archive-meta-docs.md](docprinciples-archive-meta-docs.md) - Archive or streamline DOCUMENTATION_IMPROVEMENTS and MEDIUM_PRIORITY_IMPROVEMENTS_COMPLETED
4. [docprinciples-config-example-linking.md](docprinciples-config-example-linking.md) - Replace redundant YAML blocks with links to config/experiments.example.yml
5. [docprinciples-add-glossary.md](docprinciples-add-glossary.md) - Create docs/glossary.md with preferred terms
6. [docprinciples-trim-verbosity.md](docprinciples-trim-verbosity.md) - Trim narrative in mcp-integration, conversation-flows, prompts-guide
7. [docprinciples-strengthen-navigation.md](docprinciples-strengthen-navigation.md) - Add Prerequisites to routes; verify navigation links
8. [docprinciples-simplify-readme-file-ref.md](docprinciples-simplify-readme-file-ref.md) - Simplify or remove File Reference table in docs/README.md

---

## Key References

- [Repository_Evolution_Proposal.md](../Repository_Evolution_Proposal.md) - Source of truth for requirements
- [infra/postgres-schema-overview.sql](../infra/postgres-schema-overview.sql) - Current database schema
- [services/assignment-service/API_SPEC.md](../services/assignment-service/API_SPEC.md) - Assignment service API
- [services/assignment-service/DESIGN.md](../services/assignment-service/DESIGN.md) - Assignment service design
- [docs/data-model.md](../docs/data-model.md) - Data model documentation
- [Structured_Chatbot_Requirements.md](../Structured_Chatbot_Requirements.md) - Chatbot requirements

---

## Status Legend

- **Ready** - Work item is ready to start (dependencies met)
- **In Progress** - Work item is currently being worked on
- **Blocked** - Work item cannot proceed due to missing dependencies
- **Completed** - Work item is finished (move to ../completed/)

---

## Notes

- All work items maintain backward compatibility with existing ML projects
- Database migrations follow: design schema → create migration → update schema overview
- Service specifications follow: API spec → design doc → implementation (implementation out of scope)
- Each work item is independently executable within its phase constraints
