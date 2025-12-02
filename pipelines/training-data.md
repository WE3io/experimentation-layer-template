# Training Data Pipeline

**Purpose**  
This document specifies the pipeline for generating training datasets from event logs.

---

## Start Here If…

- **Training Route** → Core document for dataset generation
- **Understanding data flow** → Read section 2
- **Dataset format** → Read section 3, then go to [../datasets/README.md](../datasets/README.md)

---

## 1. Pipeline Overview

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  exp.events     │ ──► │  Join Domain    │ ──► │  Build Training │
│  (raw logs)     │     │  Tables         │     │  Examples       │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                                                        │
                                                        ▼
                                               ┌─────────────────┐
                                               │  Write Parquet  │
                                               │  /datasets/...  │
                                               └─────────────────┘
```

---

## 2. Pipeline Steps (Pseudo-code)

### 2.1 Extract Events

```pseudo
function extract_events(start_date, end_date):
    # Query plan generation and acceptance events
    events = db.query("""
        SELECT 
            e.*,
            e.context->>'policy_version_id' as policy_version_id,
            e.payload as event_payload
        FROM exp.events e
        WHERE e.event_type IN ('plan_generated', 'plan_accepted')
        AND e.timestamp BETWEEN ? AND ?
        ORDER BY e.unit_id, e.timestamp
    """, start_date, end_date)
    
    return events
```

### 2.2 Join Domain Tables

```pseudo
function enrich_event(event):
    # Get household data
    household = db.query("""
        SELECT * FROM households 
        WHERE id = ?
    """, event.unit_id)
    
    # Get pantry snapshot at event time
    pantry = db.query("""
        SELECT * FROM pantry_snapshots
        WHERE household_id = ?
        AND snapshot_time <= ?
        ORDER BY snapshot_time DESC
        LIMIT 1
    """, event.unit_id, event.timestamp)
    
    # Get constraints
    constraints = db.query("""
        SELECT * FROM household_constraints
        WHERE household_id = ?
    """, event.unit_id)
    
    return {
        "event": event,
        "household": household,
        "pantry": pantry,
        "constraints": constraints
    }
```

### 2.3 Build Training Examples

```pseudo
function build_training_example(enriched_event):
    event = enriched_event.event
    
    # Build input context
    input_context = {
        "household": {
            "id": enriched_event.household.id,
            "size": enriched_event.household.size,
            "preferences": enriched_event.household.preferences,
            "restrictions": enriched_event.household.dietary_restrictions
        },
        "pantry": {
            "items": enriched_event.pantry.items
        },
        "constraints": {
            "budget": enriched_event.constraints.budget,
            "max_prep_time": enriched_event.constraints.max_prep_time,
            "excluded_ingredients": enriched_event.constraints.excluded
        },
        "workflow_type": event.context.get("workflow_type", "plan-first"),
        "mode": event.context.get("mode", "autopilot"),
        "previous_plan": get_previous_plan(event.unit_id, event.timestamp)
    }
    
    # Build target output
    target = {
        "accepted_plan": event.payload.get("plan"),
        "user_edits": get_user_edits(event.payload.get("plan_id"))
    }
    
    # Metadata
    metadata = {
        "timestamp": event.timestamp,
        "policy_version_id": event.policy_version_id,
        "event_id": event.id
    }
    
    return {
        "input": input_context,
        "target": target,
        "metadata": metadata
    }
```

### 2.4 Write Dataset

```pseudo
function write_dataset(examples, dataset_date):
    # Convert to DataFrame
    df = to_dataframe(examples)
    
    # Define output path
    output_path = f"/datasets/planner/{dataset_date}"
    
    # Write parquet
    df.to_parquet(f"{output_path}/training.parquet")
    
    # Write schema
    schema = generate_schema(df)
    write_json(schema, f"{output_path}/schema.json")
    
    # Write summary
    summary = generate_summary(df, dataset_date)
    write_markdown(summary, f"{output_path}/dataset_summary.md")
    
    # Log to MLflow
    with mlflow.start_run():
        mlflow.log_artifact(f"{output_path}/schema.json")
        mlflow.set_tag("dataset_version", dataset_date)
        mlflow.log_metric("row_count", len(df))
```

---

## 3. Output Format

### 3.1 Directory Structure

```
/datasets/planner/2025-01-03/
  training.parquet
  schema.json
  dataset_summary.md
```

### 3.2 Parquet Schema

```json
{
  "fields": [
    {"name": "input", "type": "struct", "fields": [
      {"name": "household", "type": "struct"},
      {"name": "pantry", "type": "struct"},
      {"name": "constraints", "type": "struct"},
      {"name": "workflow_type", "type": "string"},
      {"name": "mode", "type": "string"},
      {"name": "previous_plan", "type": "struct"}
    ]},
    {"name": "target", "type": "struct", "fields": [
      {"name": "accepted_plan", "type": "struct"},
      {"name": "user_edits", "type": "array"}
    ]},
    {"name": "metadata", "type": "struct", "fields": [
      {"name": "timestamp", "type": "timestamp"},
      {"name": "policy_version_id", "type": "string"},
      {"name": "event_id", "type": "string"}
    ]}
  ]
}
```

---

## 4. Scheduling

### 4.1 Airflow DAG (Pseudo-code)

```pseudo
# TODO: Implement actual DAG

dag = DAG(
    dag_id="training_data_generation",
    schedule_interval="0 2 * * *",  # Daily at 2am
    catchup=False
)

@task
def generate_training_data(execution_date):
    start_date = execution_date - timedelta(days=7)
    end_date = execution_date
    
    events = extract_events(start_date, end_date)
    enriched = [enrich_event(e) for e in events]
    examples = [build_training_example(e) for e in enriched]
    
    write_dataset(examples, execution_date.strftime("%Y-%m-%d"))
```

---

## 5. Quality Checks

### 5.1 Validation Rules

```pseudo
function validate_dataset(df):
    errors = []
    
    # Check minimum row count
    if len(df) < 1000:
        errors.append("Insufficient rows (< 1000)")
    
    # Check for nulls in required fields
    required_fields = ["input.household.id", "target.accepted_plan"]
    for field in required_fields:
        null_count = df[field].isnull().sum()
        if null_count > 0:
            errors.append(f"Null values in {field}: {null_count}")
    
    # Check field distributions
    # TODO: Add statistical validation
    
    return errors
```

---

## 6. TODO: Implementation Notes

- [ ] Implement extraction queries
- [ ] Set up domain table access
- [ ] Configure Airflow DAG
- [ ] Add data quality monitoring
- [ ] Set up alerting for failures

---

## Related Documentation

| Document | Purpose |
|----------|---------|
| [../datasets/README.md](../datasets/README.md) | Dataset conventions |
| [../docs/training-workflow.md](../docs/training-workflow.md) | Training process |
| [../docs/data-model.md](../docs/data-model.md) | Event schema |

