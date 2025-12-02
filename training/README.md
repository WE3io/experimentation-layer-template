# Training Templates

**Purpose**  
This directory contains training script templates and configuration for model training.

---

## Start Here If…

- **Training Route** → Read this, then follow templates
- **Running training** → Go to section 3
- **Understanding workflow** → Go to [../docs/training-workflow.md](../docs/training-workflow.md)

---

## 1. Directory Structure

```
/training/
  README.md             ← You are here
  train_planner.py      ← Main training script template
  config/
    training_config.example.yaml
  utils/
    data_loader.py      ← Dataset loading utilities
    metrics.py          ← Training metrics
```

---

## 2. Training Script Template

See [train_planner.py](train_planner.py) for the full template.

### 2.1 Key Components

```pseudo
# Pseudo-code structure

# 1. Parse arguments
args = parse_args()

# 2. Initialize MLflow
mlflow.set_experiment("planner_training")

# 3. Load dataset
dataset = load_dataset(args.dataset)

# 4. Load base model
model = load_base_model(args.model_base)

# 5. Configure fine-tuning (LoRA)
model = apply_lora(model, lora_config)

# 6. Train
for epoch in epochs:
    train_loss = train(model, dataset)
    val_loss = validate(model, dataset)
    
    mlflow.log_metrics({
        "train_loss": train_loss,
        "val_loss": val_loss
    })

# 7. Save and register
save_model(model)
mlflow.register_model(model_uri, "planner_model")
```

---

## 3. Running Training

### 3.1 Prerequisites

- Dataset available in `/datasets/planner/{date}/`
- MLflow tracking server accessible
- GPU available (≥24GB VRAM recommended)

### 3.2 Command

```bash
python training/train_planner.py \
    --dataset=/datasets/planner/2025-01-03 \
    --model_base=llama-3-8b \
    --epochs=3 \
    --lr=1e-4 \
    --batch_size=16 \
    --output_dir=./output
```

### 3.3 Environment Variables

```bash
export MLFLOW_TRACKING_URI="http://mlflow:5000"
export MLFLOW_S3_ENDPOINT_URL="http://minio:9000"
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
```

---

## 4. Configuration

See [config/training_config.example.yaml](config/training_config.example.yaml) for configuration options.

### 4.1 Key Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `learning_rate` | Learning rate | 1e-4 |
| `batch_size` | Training batch size | 16 |
| `epochs` | Number of epochs | 3 |
| `lora_r` | LoRA rank | 16 |
| `lora_alpha` | LoRA alpha | 32 |

---

## 5. MLflow Logging Requirements

Every training run MUST log:

### 5.1 Parameters

```python
mlflow.log_params({
    "learning_rate": lr,
    "batch_size": batch_size,
    "epochs": epochs,
    "dataset_version": dataset_date,
    "model_base": model_name,
    "fine_tuning_method": "lora",
    "lora_r": lora_r,
    "lora_alpha": lora_alpha
})
```

### 5.2 Metrics

```python
mlflow.log_metrics({
    "train_loss": train_loss,
    "val_loss": val_loss
}, step=epoch)
```

### 5.3 Tags

```python
mlflow.set_tags({
    "policy_id": "planner_policy",
    "task": "planner",
    "dataset_version": dataset_date
})
```

### 5.4 Artefacts

```python
mlflow.log_artifacts("./output/model", artifact_path="model")
mlflow.log_artifact("./output/tokenizer", artifact_path="tokenizer")
```

---

## 6. Post-Training

After training completes:

1. **Verify registration**
   ```bash
   mlflow models list --name planner_model
   ```

2. **Run offline evaluation**
   ```bash
   python pipelines/offline_replay.py \
       --model_name=planner_model \
       --model_version=<new_version> \
       --dataset=/datasets/planner/2025-01-03
   ```

3. **Create policy version** (if evaluation passes)

---

## 7. TODO: Implementation Notes

- [ ] Implement training script
- [ ] Add data loading utilities
- [ ] Configure LoRA/QLoRA
- [ ] Add checkpointing
- [ ] Add early stopping

---

## Related Documentation

| Document | Purpose |
|----------|---------|
| [../docs/training-workflow.md](../docs/training-workflow.md) | Training process |
| [../docs/mlflow-guide.md](../docs/mlflow-guide.md) | MLflow usage |
| [../datasets/README.md](../datasets/README.md) | Dataset format |

