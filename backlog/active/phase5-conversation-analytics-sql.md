# Phase 5: Add SQL Queries for Funnel Analysis

## Outcome

A new SQL file `analytics/conversation-analytics.sql` exists with queries for chatbot analytics. The file:
- Contains queries for funnel analysis (conversation progression)
- Contains queries for drop-off detection (where users abandon flows)
- Contains queries for completion rate by flow
- Contains queries for average turn count and time to completion
- Contains queries for satisfaction score analysis

A reviewer can use these queries in Metabase or directly to analyze conversation performance.

## Constraints & References

- **Location:** `analytics/conversation-analytics.sql`
- **Pattern:** Follow structure of `analytics/example-queries.sql`
- **Event types:** Conversation event types (after phase5-event-schema-extension-docs.md)
- **Metabase models:** Chatbot metrics models (after phase5-metabase-chatbot-models.md)

## Acceptance Checks

- [ ] File `analytics/conversation-analytics.sql` created
- [ ] Funnel analysis queries included
- [ ] Drop-off detection queries included
- [ ] Completion rate queries included
- [ ] Turn count queries included
- [ ] Time to completion queries included
- [ ] Satisfaction score queries included
- [ ] Queries include comments explaining purpose
- [ ] Queries follow existing SQL style

## Explicit Non-Goals

- Does not create Metabase models (separate work item)
- Does not implement analytics pipeline (separate work item)
- Does not configure dashboards (queries only)
- Does not write pipeline code (SQL queries only)
