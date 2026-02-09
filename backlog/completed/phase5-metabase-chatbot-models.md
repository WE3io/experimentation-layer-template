# Phase 5: Create Metabase Models for Chatbot Metrics

## Outcome

The Metabase models documentation (`analytics/metabase-models.md`) is extended with chatbot-specific metrics and models. The documentation:
- Documents conversation metrics (completion rate, turn count, time to completion, satisfaction)
- Creates Metabase models/views for chatbot analytics
- Documents funnel analysis setup
- Documents drop-off analysis setup
- Includes example queries for chatbot dashboards

A reviewer can read the Metabase models doc and understand how to build chatbot analytics dashboards.

## Constraints & References

- **Current file:** `analytics/metabase-models.md`
- **Proposal reference:** `Repository_Evolution_Proposal.md` section 3.4 (Conversation Analytics)
- **Event types:** Conversation event types (after phase5-event-schema-extension-docs.md)
- **Pattern:** Follow existing Metabase models structure

## Acceptance Checks

- [ ] `analytics/metabase-models.md` updated with chatbot metrics section
- [ ] Conversation metrics documented (completion rate, turn count, time to completion, satisfaction)
- [ ] Metabase models/views for chatbot analytics documented
- [ ] Funnel analysis setup documented
- [ ] Drop-off analysis setup documented
- [ ] Example queries included
- [ ] Documentation matches existing Metabase models style

## Explicit Non-Goals

- Does not create SQL queries file (separate work item)
- Does not configure Metabase dashboards (documentation only)
- Does not implement analytics pipeline (separate work item)
- Does not create actual Metabase models (documentation only)
