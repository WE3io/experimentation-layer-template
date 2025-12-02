# Training Workflow

**Purpose**  
This document explains how to prepare datasets, run training jobs, and register models in MLflow.

---

## Start Here If…

- **Full sequential workflow** → Continue from [mlflow-guide.md](mlflow-guide.md)
- **Training Route** → This is your entry point
- **Dataset preparation only** → Focus on section 2
- **Running training** → Focus on section 3

---

## 1. Overview

The training workflow consists of four phases:

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│ 1. Generate     │ ──► │ 2. Run          │ ──► │ 3. Register     │ ──► │ 4. Evaluate     │
│    Dataset      │     │    Training     │     │    Model        │     │    Offline      │
└─────────────────┘     └─────────────────┘     └─────────────────┘     └─────────────────┘
```

---

## 2. Dataset Preparation

### 2.1 Dataset Requirements

Each training row must include:

| Field | Description | Example |
|-------|-------------|---------|
| **Input Context** | All information available at plan time | household, pantry, constraints |
| **Target Output** | What the model should produce | accepted plan, edits |
| **Metadata** | Tracking information | timestamp, policy_version_id |

### 2.2 Input Context Fields

```json
{
  "household": {
    "id": "uuid",
    "size": 4,
    "preferences": ["vegetarian"],
    "restrictions": ["nut-allergy"]
  },
  "pantry": {
    "items": [
      {"name": "rice", "quantity": 2, "unit": "kg"},
      {"name": "tomatoes", "quantity": 6, "unit": "count"}
    ]
  },
  "constraints": {
    "budget": 150,
    "max_prep_time": 45,
    "excluded_ingredients": ["shellfish"]
  },
  "workflow_type": "plan-first",
  "mode": "autopilot",
  "previous_plan": { ... }
}
```

### 2.3 Target Output Fields

```json
{
  "accepted_plan": {
    "meals": [
      {"day": "monday", "recipe_id": "uuid", "servings": 4},
      {"day": "tuesday", "recipe_id": "uuid", "servings": 4}
    ]
  },
  "user_edits": [
    {"type": "swap_meal", "day": "tuesday", "from": "uuid", "to": "uuid"},
    {"type": "adjust_servings", "day": "monday", "servings": 6}
  ]
}
```

### 2.4 Dataset Pipeline (Pseudo-code)

```pseudo
# Step 1: Extract events
events = db.query("""
    SELECT * FROM exp.events 
    WHERE event_type IN ('plan_generated', 'plan_accepted')
    AND timestamp BETWEEN ? AND ?
""", start_date, end_date)

# Step 2: Join with domain tables
for event in events:
    household = get_household(event.unit_id)
    pantry = get_pantry(event.unit_id, event.timestamp)
    constraints = get_constraints(event.unit_id)
    
    # Step 3: Construct training example
    training_row = {
        "input": {
            "household": household,
            "pantry": pantry,
            "constraints": constraints,
            "workflow_type": event.context.workflow_type,
            "mode": event.context.mode,
            "previous_plan": get_previous_plan(event.unit_id)
        },
        "target": {
            "accepted_plan": event.payload.plan,
            "user_edits": get_user_edits(event.payload.plan_id)
        },
        "metadata": {
            "timestamp": event.timestamp,
            "policy_version_id": event.context.policy_version_id
        }
    }
    
    dataset.append(training_row)

# Step 4: Write dataset
write_parquet(dataset, f"/datasets/planner/{date}/training.parquet")

# Step 5: Log in MLflow
mlflow.log_artifact(schema_file)
mlflow.set_tag("dataset_version", date)
```

### 2.5 Dataset Storage Structure

```
/datasets/
  /planner/
    /2025-01-03/
      training.parquet     ← Main dataset
      schema.json          ← Field definitions
      dataset_summary.md   ← Statistics and notes
    /2025-01-10/
      ...
```

### 2.6 Dataset Summary Example

```markdown
# Dataset: planner/2025-01-03

**Rows**: 14,287
**Fields**: 34
**Task**: Weekly plan generation (supervised)
**Targets**: Accepted meal plans

## Coverage
- Households: 2,341
- Date range: 2024-12-01 to 2025-01-02
- Workflow types: plan-first (60%), meal-first (30%), pantry-first (10%)

## Notes
- Includes constraints and pantry features
- Excludes incomplete sessions
- Policy versions: v1, v2
```

See [../datasets/README.md](../datasets/README.md) for full conventions.

---

## 3. Running Training

### 3.1 Training Environment

| Component | Requirement |
|-----------|-------------|
| GPU | NVIDIA with ≥24GB VRAM |
| MLflow | Tracking server accessible |
| Storage | S3/MinIO for artefacts |

### 3.2 Training Script Template

```pseudo
# training/train_planner.py

function main(args):
    # 1. Initialize MLflow
    mlflow.set_experiment("planner_training")
    
    with mlflow.start_run():
        # 2. Log parameters
        mlflow.log_params({
            "dataset_version": args.dataset,
            "model_base": args.model_base,
            "epochs": args.epochs,
            "learning_rate": args.lr,
            "batch_size": args.batch_size,
            "fine_tuning_method": "lora"
        })
        
        # 3. Load dataset
        dataset = load_parquet(f"{args.dataset}/training.parquet")
        train_set, val_set = split_dataset(dataset, 0.9, 0.1)
        
        # 4. Load base model
        model = load_base_model(args.model_base)
        tokenizer = load_tokenizer(args.model_base)
        
        # 5. Configure LoRA
        lora_config = configure_lora(
            r=16,
            alpha=32,
            target_modules=["q_proj", "v_proj"]
        )
        model = apply_lora(model, lora_config)
        
        # 6. Train
        for epoch in range(args.epochs):
            train_loss = train_epoch(model, train_set)
            val_loss = evaluate(model, val_set)
            
            mlflow.log_metrics({
                "train_loss": train_loss,
                "val_loss": val_loss
            }, step=epoch)
        
        # 7. Save artefacts
        save_model(model, "./output/model")
        save_tokenizer(tokenizer, "./output/tokenizer")
        
        mlflow.log_artifacts("./output", artifact_path="model")
        
        # 8. Register model
        model_uri = f"runs:/{mlflow.active_run().info.run_id}/model"
        registered = mlflow.register_model(model_uri, "planner_model")
        
        print(f"Registered: planner_model version {registered.version}")
```

### 3.3 Running Training

```bash
# Example command
python training/train_planner.py \
    --dataset=/datasets/planner/2025-01-03 \
    --model_base=llama-3-8b \
    --epochs=3 \
    --lr=1e-4 \
    --batch_size=16
```

---

## 4. Post-Training Steps

### 4.1 Verify Registration

```pseudo
# Check model was registered
client = mlflow.MlflowClient()
versions = client.search_model_versions("name='planner_model'")
latest = max(versions, key=lambda v: int(v.version))
print(f"Latest version: {latest.version}")
```

### 4.2 Run Offline Evaluation

Before any model is tested online, run offline evaluation:

```bash
python pipelines/offline_replay.py \
    --model_name=planner_model \
    --model_version=4 \
    --dataset=/datasets/planner/2025-01-03
```

See [offline-evaluation.md](offline-evaluation.md) for details.

### 4.3 Mark as Candidate (If Passes)

```pseudo
if offline_eval_passes:
    mlflow.set_tag("stage", "candidate")
```

---

## 5. Quick-Start Checklist

For developers new to this workflow:

| Step | Action | Reference |
|------|--------|-----------|
| 1 | Generate dataset | Section 2 |
| 2 | Verify dataset version | [../datasets/](../datasets/) |
| 3 | Run training script | Section 3 |
| 4 | Verify MLflow registration | [mlflow-guide.md](mlflow-guide.md) |
| 5 | Run offline evaluation | [offline-evaluation.md](offline-evaluation.md) |
| 6 | Create policy version | [model-promotion.md](model-promotion.md) |
| 7 | Create experiment variant | [experiments.md](experiments.md) |
| 8 | Monitor via Metabase | [../analytics/metabase-models.md](../analytics/metabase-models.md) |

---

## 6. Common Pitfalls

### 6.1 Dataset Shape Mismatch

**Problem**: Training rows don't match planning prompt structure  
**Solution**: Ensure pipeline mirrors real request shape

### 6.2 Missing MLflow Logging

**Problem**: Training completes but no metrics visible  
**Solution**: Check `MLFLOW_TRACKING_URI` is set

### 6.3 Artefact Storage Failure

**Problem**: Model not saved to S3/MinIO  
**Solution**: Verify S3 credentials and bucket access

### 6.4 Out of Memory

**Problem**: GPU OOM during training  
**Solution**: Reduce batch size, use gradient checkpointing

---

## 7. Related Documentation

| Document | Purpose |
|----------|---------|
| [mlflow-guide.md](mlflow-guide.md) | MLflow usage |
| [offline-evaluation.md](offline-evaluation.md) | Evaluation process |
| [model-promotion.md](model-promotion.md) | Promotion lifecycle |
| [../datasets/README.md](../datasets/README.md) | Dataset conventions |
| [../training/](../training/) | Training templates |

---

## After Completing This Document

You will understand:
- How to prepare training datasets
- The structure of training rows
- How to run training with MLflow
- Post-training verification steps

**Next Step**: [offline-evaluation.md](offline-evaluation.md)

