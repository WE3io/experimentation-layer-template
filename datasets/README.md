# Datasets

**Purpose**  
This directory contains training datasets and conventions for dataset management.

---

## Start Here If…

- **Training Route** → Understand dataset format here
- **Generating datasets** → Go to [../pipelines/training-data.md](../pipelines/training-data.md)
- **Understanding structure** → Read all sections

---

## 1. Directory Structure

```
/datasets/
  README.md                 ← You are here
  /planner/                 ← Model-specific datasets
    /2025-01-03/           ← Date-versioned dataset
      training.parquet     ← Main training data
      schema.json          ← Field definitions
      dataset_summary.md   ← Statistics and notes
    /2025-01-10/
      ...
  /meal_ranker/            ← Another model
    /2025-01-05/
      ...
```

---

## 2. Dataset Naming Conventions

### 2.1 Directory Naming

| Pattern | Example | Purpose |
|---------|---------|---------|
| `/{model_name}/` | `/planner/` | Model-specific datasets |
| `/{model_name}/{date}/` | `/planner/2025-01-03/` | Date-versioned dataset |

### 2.2 File Naming

| File | Purpose |
|------|---------|
| `training.parquet` | Main training data |
| `validation.parquet` | Optional separate validation set |
| `schema.json` | Field definitions and types |
| `dataset_summary.md` | Human-readable summary |

---

## 3. Dataset Format

### 3.1 Required Fields

Each training example MUST include:

```json
{
  "input": {
    // All information available at inference time
  },
  "target": {
    // Expected output
  },
  "metadata": {
    // Tracking information
  }
}
```

### 3.2 Planner Dataset Schema

```json
{
  "input": {
    "household": {
      "id": "string",
      "size": "integer",
      "preferences": ["string"],
      "restrictions": ["string"]
    },
    "pantry": {
      "items": [
        {"name": "string", "quantity": "float", "unit": "string"}
      ]
    },
    "constraints": {
      "budget": "float",
      "max_prep_time": "integer",
      "excluded_ingredients": ["string"]
    },
    "workflow_type": "string",
    "mode": "string",
    "previous_plan": "object | null"
  },
  "target": {
    "accepted_plan": {
      "meals": [
        {"day": "string", "recipe_id": "string", "servings": "integer"}
      ]
    },
    "user_edits": [
      {"type": "string", "details": "object"}
    ]
  },
  "metadata": {
    "timestamp": "datetime",
    "policy_version_id": "string",
    "event_id": "string"
  }
}
```

---

## 4. Schema File Format

### 4.1 schema.json Structure

```json
{
  "version": "1.0",
  "model": "planner",
  "created_at": "2025-01-03T00:00:00Z",
  "fields": [
    {
      "name": "input",
      "type": "struct",
      "nullable": false,
      "fields": [
        {
          "name": "household",
          "type": "struct",
          "fields": [
            {"name": "id", "type": "string"},
            {"name": "size", "type": "integer"}
          ]
        }
      ]
    },
    {
      "name": "target",
      "type": "struct",
      "nullable": false,
      "fields": []
    },
    {
      "name": "metadata",
      "type": "struct",
      "nullable": false,
      "fields": []
    }
  ]
}
```

---

## 5. Dataset Summary Format

### 5.1 Template

```markdown
# Dataset: {model_name}/{date}

**Generated**: {generation_timestamp}
**Pipeline Version**: {pipeline_version}

## Overview

| Metric | Value |
|--------|-------|
| Total Rows | {row_count} |
| Fields | {field_count} |
| Size | {file_size} |

## Coverage

| Dimension | Value |
|-----------|-------|
| Households | {unique_households} |
| Date Range | {start_date} to {end_date} |
| Policy Versions | {policy_versions} |

## Distribution

### Workflow Types
| Type | Count | Percentage |
|------|-------|------------|
| plan-first | {count} | {pct}% |
| meal-first | {count} | {pct}% |
| pantry-first | {count} | {pct}% |

### Modes
| Mode | Count | Percentage |
|------|-------|------------|
| autopilot | {count} | {pct}% |
| exploratory | {count} | {pct}% |
| constrained | {count} | {pct}% |

## Quality Checks

- [ ] No null values in required fields
- [ ] All timestamps valid
- [ ] All household IDs exist
- [ ] Schema matches expected format

## Notes

{any_special_notes}
```

---

## 6. Versioning

### 6.1 Dataset Versions

- Each date creates a new version
- Versions are immutable once created
- Use date as version identifier

### 6.2 Referencing Datasets

In training:
```yaml
dataset:
  path: "/datasets/planner/2025-01-03"
```

In MLflow:
```python
mlflow.set_tag("dataset_version", "2025-01-03")
```

---

## 7. Storage

### 7.1 Location

| Environment | Location |
|-------------|----------|
| Local | `/data/datasets/` |
| Staging | `s3://staging-datasets/` |
| Production | `s3://prod-datasets/` |

### 7.2 Retention

| Age | Action |
|-----|--------|
| < 30 days | Full access |
| 30-90 days | Archive to cold storage |
| > 90 days | Delete (unless referenced by active model) |

---

## 8. Example Dataset

### 8.1 Sample Row

```json
{
  "input": {
    "household": {
      "id": "hh-12345",
      "size": 4,
      "preferences": ["vegetarian"],
      "restrictions": ["nut-allergy"]
    },
    "pantry": {
      "items": [
        {"name": "rice", "quantity": 2.0, "unit": "kg"},
        {"name": "tomatoes", "quantity": 6, "unit": "count"},
        {"name": "olive oil", "quantity": 0.5, "unit": "L"}
      ]
    },
    "constraints": {
      "budget": 150.00,
      "max_prep_time": 45,
      "excluded_ingredients": ["shellfish", "peanuts"]
    },
    "workflow_type": "plan-first",
    "mode": "autopilot",
    "previous_plan": null
  },
  "target": {
    "accepted_plan": {
      "meals": [
        {"day": "monday", "recipe_id": "rec-001", "servings": 4},
        {"day": "tuesday", "recipe_id": "rec-002", "servings": 4},
        {"day": "wednesday", "recipe_id": "rec-003", "servings": 4},
        {"day": "thursday", "recipe_id": "rec-004", "servings": 4},
        {"day": "friday", "recipe_id": "rec-005", "servings": 4}
      ]
    },
    "user_edits": [
      {
        "type": "swap_meal",
        "day": "tuesday",
        "from_recipe": "rec-002",
        "to_recipe": "rec-006"
      }
    ]
  },
  "metadata": {
    "timestamp": "2025-01-02T14:30:00Z",
    "policy_version_id": "pv-v2",
    "event_id": "evt-98765"
  }
}
```

---

## 9. TODO: Implementation Notes

- [ ] Set up S3 bucket structure
- [ ] Implement dataset validation scripts
- [ ] Add dataset lineage tracking
- [ ] Configure retention automation

---

## Related Documentation

| Document | Purpose |
|----------|---------|
| [../pipelines/training-data.md](../pipelines/training-data.md) | Dataset generation |
| [../docs/training-workflow.md](../docs/training-workflow.md) | Using datasets |
| [../training/README.md](../training/README.md) | Training scripts |

