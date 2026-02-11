# Traditional ML Experiment Example

This example demonstrates the end-to-end lifecycle for a traditional machine learning project on the platform.

## Overview

In a traditional ML project, the execution strategy is `mlflow_model`. The workflow involves:
1. Generating a training dataset from logged events.
2. Training or fine-tuning a model using `train_planner.py`.
3. Logging metrics, parameters, and the model artifact to **MLflow**.
4. Registering the model in the **MLflow Model Registry**.
5. Promoting the model to a production-ready experiment variant.

## Contents

- `training/train_planner.py`: The core training script template.
- `datasets/example_ml/training.parquet`: A sample dataset in Parquet format.
- `config/experiments.example.yml`: Example of how to configure an experiment with an `mlflow_model` strategy.

## Quick Start

### 1. Set up Infrastructure
Ensure the local stack is running:
```bash
cd infra
docker-compose up -d
```

### 2. Run Training
Execute the training script to train a model and register it in MLflow:
```bash
python training/train_planner.py 
    --dataset=datasets/example_ml/training.parquet 
    --epochs=5 
    --lr=0.001
```

### 3. Verify in MLflow
Open the MLflow UI at [http://localhost:5000](http://localhost:5000) to view your training run, logged metrics, and the registered `planner_model`.

### 4. Configure Experiment
Update your `experiments.yml` to use the newly registered model:
```yaml
experiments:
  - name: planner_policy_exp
    unit_type: user
    variants:
      - name: treatment_v1
        allocation: 0.5
        config:
          execution_strategy: "mlflow_model"
          mlflow_model:
            policy_version_id: "auto-generated-id"
            model_name: "planner_model"
          params:
            temperature: 0.7
```

## Related Documentation

- [Training Workflow](../../docs/training-workflow.md)
- [MLflow Guide](../../docs/mlflow-guide.md)
- [Model Promotion](../../docs/model-promotion.md)
