# **Training & Fine-Tuning Guide for the Experimentation System**

**Purpose**  
This document explains how to prepare datasets, run training or fine-tuning jobs, register models, evaluate them offline, and promote them into controlled experiments. It builds directly on the structures defined in the experimentation template.

---

## **1. Overview**

The system supports two model lifecycle actions:

1. **Training or Fine-Tuning**  
   - Produces a new model artefact.
   - Logs metrics and parameters.
   - Registers model versions in MLflow.

2. **Offline & Online Evaluation**  
   - Offline replay compares a policy/model against historical requests.
   - Online experiments test behaviour safely under real traffic.

All models used by the planner or policy layers are versioned and tracked through MLflow.

---

# **2. Dataset Preparation**

Training requires structured datasets derived from the application’s event logs and domain tables. The pipeline produces **supervised training rows** used for fine-tuning open-source models.

## **2.1 Inputs to the Dataset**

- `exp.events` table (raw logs)
- Household, pantry, recipe, and constraint tables (domain-specific)
- Policy and model version metadata

## **2.2 Required Columns for Planner Datasets**

Each training row should contain:

- **Input context**:
  - Household representation  
  - Workflow type (`plan-first`, `meal-first`, `pantry-first`)
  - Pantry snapshot  
  - Constraints snapshot  
  - Mode (`autopilot`, `exploratory`, `constrained`) if available  
  - Previous weekly plan (optional)
- **Target output**:
  - Accepted plan  
  - Accepted meals  
  - Sequence of user edits (optional but valuable)
- **Metadata**:
  - Timestamp  
  - Policy version used originally  
  - Segmenting features (region, household size etc.)

## **2.3 Dataset Pipeline (Pseudo-Workflow)**

```pseudo
1. Extract raw rows from exp.events
   WHERE event_type IN ('plan_generated', 'plan_accepted')

2. Join with household, pantry, recipe, constraint tables.

3. For each plan:
   Build a training example:
     input = {
        household: {...},
        pantry: {...},
        constraints: {...},
        workflow_type: "...",
        mode: "...",
        previous_plan: {...}
     }

     target = {
        accepted_plan: {...},
        user_edits: [...]
     }

4. Write dataset as parquet under:
   /datasets/planner/YYYY-MM-DD/training.parquet

5. Register dataset version in MLflow as artefact or log metadata tag.
```

## **2.4 Dataset Storage Conventions**

- All datasets stored under `/datasets/{model_name}/{date}/`
- Each dataset folder should include:
  - `training.parquet`  
  - `schema.json`  
  - `dataset_summary.md`  

Example summary:

```
Rows: 14,287
Fields: 34
Tasks: Weekly plan generation (supervised)
Targets: Accepted meal plans
Notes: Includes constraints and pantry features
```

---

# **3. Training & Fine-Tuning**

The system uses MLflow for tracking and registering run results.

## **3.1 Training Environment (Opinionated Baseline)**

- Local GPU workstation or remote GPU instance (e.g. LambdaLabs/Runpod).
- MLflow Tracking Server accessible via `MLFLOW_TRACKING_URI`.
- Artefact storage: S3/MinIO bucket.

## **3.2 Required MLflow Logging (Minimum)**

Every training script must log:

- `params`:  
  - learning rate  
  - batch size  
  - epochs  
  - dataset version  
  - model architecture (e.g. llama-3-8b)

- `metrics`:  
  - training loss  
  - validation loss  
  - eval score(s) produced by offline evaluator

- `artefacts`:  
  - trained model  
  - tokeniser  
  - config files

- `tags`:  
  - `policy_id` (if relevant)  
  - `task=planner`  
  - `dataset_version`  

## **3.3 Training Process (Pseudo-Steps)**

```pseudo
1. developer selects dataset version

2. developer runs training script:
     python train_planner.py \
        --dataset=/datasets/planner/2025-01-03 \
        --model_base=llama3 \
        --epochs=3

3. training script:
     - loads dataset
     - loads base open-source model
     - trains/fine-tunes with LoRA/QLoRA
     - logs params + metrics to MLflow
     - saves model artefacts
     - registers model in MLflow Model Registry:
         "planner_model", version=N

4. MLflow returns model version URI:
     models:/planner_model/N
```

You do **not** need to specify training code — just enforce what must be logged and registered.

---

# **4. Offline Evaluation**

Before any new model can be tested online, two checks are required:

1. **Offline replay evaluation**
2. **Comparison against baseline**

Offline evaluation uses the same model artefact and dataset structures defined earlier.

## **4.1 Replay Job (Pseudo-Workflow)**

```pseudo
1. Load dataset D (full or sample).

2. For each training row:
     - call run_policy(model, input_context)
     - generate candidate plan
     - compare with target plan or target behaviour
     - compute evaluation metrics:
         - plan_alignment_score
         - meal_diversity_score
         - leftovers_utility_score
         - constraint_respect_score

3. Aggregate results across dataset:
     offline_eval_score = weighted combination

4. Log results to MLflow as metrics
5. Write evaluation table into Postgres:
   exp.offline_replay_results
```

## **4.2 Minimum Evaluation Outputs**

- Alignment score vs accepted plans
- Constraint-respect score (0 violations allowed)
- Predicted vs actual user edits (proxy for plan quality)
- Diversity and leftovers metrics

---

# **5. Policy Version Creation**

Each time a new model is registered, a new policy version should be created.

## **5.1 Policy Version Row (Example)**

In `exp.policy_versions`:

```json
{
  "policy_id": "planner_policy",
  "version": 3,
  "config_defaults": {},
  "mlflow_model_name": "planner_model",
  "mlflow_model_version": "3"
}
```

This object acts as the linking point between:

- The model artefact
- The experiment system
- The orchestration layer

---

# **6. Promotion Rules**

A model can only move from “trained” to “candidate for production” after completing both offline and online checks.

## **6.1 Offline Acceptance Rules**

A new model version may be marked “candidate” if:

- Offline score ≥ baseline offline score
- Constraint-respect score = 100%
- No statistically significant degradation in:
  - plan alignment  
  - user edit prediction  
  - cost/latency proxy  

This status should be added as a tag in MLflow, e.g.:

```text
"stage"="candidate"
```

## **6.2 Online Experiment Requirements**

Before activating the model for real users:

- Create a new experiment variant pointing to the new policy version.
- Allocate ≤10% traffic for the first run.
- Monitor:
  - Plan acceptance rates
  - Edit counts
  - Validator intervention frequency
  - Latency and cost

## **6.3 Promotion to Active Use**

If the variant outperforms the baseline or meets thresholds:

- Promote MLflow model to `"production"` stage.
- Update default variant allocation or retire the baseline variant.

---

# **7. Developer Quick-Start Checklist**

For senior devs new to MLOps, provide this in `docs/training-workflow.md`:

1. **Generate dataset**  
   Run the dataset pipeline to produce training rows.

2. **Select dataset version**  
   Check `/datasets/planner/YYYY-MM-DD/`.

3. **Run training script**  
   Use MLflow to track run + register model.

4. **Run offline replay**  
   Validate alignment, safety, and utility.

5. **Create policy_version**  
   Link model artefact to policy version.

6. **Create an experiment**  
   Variant config includes `policy_version_id`.

7. **Monitor via Metabase**  
   Compare variant vs baseline metrics.

8. **Promote if successful**  
   Update MLflow stage + variant allocation.

This closes the loop in developer-friendly language.

---

# **8. Common Failure Modes (For First-Time MLOps Engineers)**

List these explicitly to save debugging time:

- **Training dataset shape mismatch**  
  → Ensure training rows mirror planning prompt structure.

- **Incorrect model registration**  
  → Check MLflow model name/version matches `policy_versions`.

- **Missing metadata in events**  
  → Must include `experiment_id`, `variant_id`, and `policy_version_id`.

- **Offline evaluation not deterministic**  
  → Keep replay pipeline deterministic by pinning model version, dataset version, and seeds.

- **Assigning too much traffic too early**  
  → Always start experiments with small allocations.

---

# **9. Summary**

This doc gives developers:

- The minimal mental model for training & fine-tuning
- How datasets are generated
- How models are logged and versioned
- How evaluation gates work
- How models enter the experimentation system safely

Together with the onboarding template, this is fully sufficient to enable senior developers to contribute to model iteration and experimentation without prior MLOps experience.