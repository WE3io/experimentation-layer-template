# Examples: ML Lifecycle & Training Skeleton

## Outcome

A functional `training/train_planner.py` skeleton and a new end-to-end example project in `examples/traditional-ml-experiment/`. This provides a concrete implementation of the model training and registration workflow for traditional ML projects.

## Constraints & References

- **Training Logic:** Must implement the pseudo-code in `training/train_planner.py`, including MLflow tracking and model registration.
- **Onboarding Path:** Aligns with `onboarding-spec.md` (Sections 8 & 9).
- **Documentation:** Follows the structure of existing examples in `examples/README.md`.
- **Dataset:** Should use a small, representative `.parquet` file as a dummy dataset.

## Acceptance Checks

- [ ] `training/train_planner.py` is updated from a template to a functional script (handles args, logs to MLflow).
- [ ] `examples/traditional-ml-experiment/` directory is created.
- [ ] New example contains a `README.md` explaining the ML project lifecycle.
- [ ] A sample dataset (`datasets/example_ml/training.parquet`) is provided for the example.
- [ ] `examples/README.md` is updated to include and link the new example.

## Explicit Non-Goals

- Implementation of actual deep learning training loops (PyTorch/TensorFlow).
- Procurement or generation of large-scale production datasets.
- Fine-tuning of real LLMs within this work item.
