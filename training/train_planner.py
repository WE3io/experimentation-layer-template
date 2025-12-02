# =============================================================================
# Training Script Template: Planner Model
# =============================================================================
# Purpose: Fine-tune a language model for meal planning
#
# Start Here If…
#   - Running training → Follow usage instructions below
#   - Understanding training → Read docs/training-workflow.md
#
# Usage:
#   python train_planner.py \
#       --dataset=/datasets/planner/2025-01-03 \
#       --model_base=llama-3-8b \
#       --epochs=3 \
#       --lr=1e-4 \
#       --batch_size=16
# =============================================================================

"""
TODO: This is a template/skeleton. Implement the actual training logic.

The script should:
1. Parse command-line arguments
2. Initialize MLflow tracking
3. Load and prepare dataset
4. Load base model
5. Apply LoRA/QLoRA configuration
6. Train with logging
7. Save and register model
"""

# -----------------------------------------------------------------------------
# Pseudo-code Implementation
# -----------------------------------------------------------------------------

"""
import argparse
import mlflow

def parse_args():
    parser = argparse.ArgumentParser(description="Train planner model")
    
    # Dataset
    parser.add_argument("--dataset", required=True, help="Path to dataset directory")
    
    # Model
    parser.add_argument("--model_base", default="llama-3-8b", help="Base model name")
    
    # Training hyperparameters
    parser.add_argument("--epochs", type=int, default=3)
    parser.add_argument("--lr", type=float, default=1e-4)
    parser.add_argument("--batch_size", type=int, default=16)
    
    # LoRA configuration
    parser.add_argument("--lora_r", type=int, default=16)
    parser.add_argument("--lora_alpha", type=int, default=32)
    
    # Output
    parser.add_argument("--output_dir", default="./output")
    
    return parser.parse_args()


def load_dataset(dataset_path):
    '''
    Load training dataset from parquet files.
    
    Args:
        dataset_path: Path to dataset directory containing training.parquet
    
    Returns:
        Training and validation datasets
    '''
    # TODO: Implement
    # df = pd.read_parquet(f"{dataset_path}/training.parquet")
    # train_set, val_set = train_test_split(df, test_size=0.1)
    # return train_set, val_set
    pass


def load_base_model(model_name):
    '''
    Load pre-trained base model.
    
    Args:
        model_name: Name/path of base model (e.g., "llama-3-8b")
    
    Returns:
        Model and tokenizer
    '''
    # TODO: Implement
    # model = AutoModelForCausalLM.from_pretrained(model_name)
    # tokenizer = AutoTokenizer.from_pretrained(model_name)
    # return model, tokenizer
    pass


def apply_lora(model, r, alpha, target_modules):
    '''
    Apply LoRA configuration to model.
    
    Args:
        model: Base model
        r: LoRA rank
        alpha: LoRA alpha
        target_modules: Modules to apply LoRA to
    
    Returns:
        Model with LoRA applied
    '''
    # TODO: Implement
    # from peft import LoraConfig, get_peft_model
    # config = LoraConfig(r=r, lora_alpha=alpha, target_modules=target_modules)
    # model = get_peft_model(model, config)
    # return model
    pass


def train_epoch(model, train_loader, optimizer):
    '''
    Train for one epoch.
    
    Returns:
        Average training loss
    '''
    # TODO: Implement
    pass


def validate(model, val_loader):
    '''
    Validate model.
    
    Returns:
        Average validation loss
    '''
    # TODO: Implement
    pass


def save_model(model, tokenizer, output_dir):
    '''
    Save model and tokenizer to output directory.
    '''
    # TODO: Implement
    # model.save_pretrained(f"{output_dir}/model")
    # tokenizer.save_pretrained(f"{output_dir}/tokenizer")
    pass


def main():
    args = parse_args()
    
    # Initialize MLflow
    mlflow.set_experiment("planner_training")
    
    with mlflow.start_run():
        # Log parameters
        mlflow.log_params({
            "learning_rate": args.lr,
            "batch_size": args.batch_size,
            "epochs": args.epochs,
            "dataset_version": args.dataset,
            "model_base": args.model_base,
            "fine_tuning_method": "lora",
            "lora_r": args.lora_r,
            "lora_alpha": args.lora_alpha
        })
        
        # Set tags
        mlflow.set_tags({
            "policy_id": "planner_policy",
            "task": "planner",
            "dataset_version": args.dataset.split("/")[-1]
        })
        
        # Load dataset
        print(f"Loading dataset from {args.dataset}")
        train_set, val_set = load_dataset(args.dataset)
        mlflow.log_metric("train_size", len(train_set))
        mlflow.log_metric("val_size", len(val_set))
        
        # Load base model
        print(f"Loading base model: {args.model_base}")
        model, tokenizer = load_base_model(args.model_base)
        
        # Apply LoRA
        print("Applying LoRA configuration")
        model = apply_lora(
            model,
            r=args.lora_r,
            alpha=args.lora_alpha,
            target_modules=["q_proj", "v_proj"]
        )
        
        # Setup training
        # optimizer = ...
        # train_loader = ...
        # val_loader = ...
        
        # Training loop
        for epoch in range(args.epochs):
            print(f"Epoch {epoch + 1}/{args.epochs}")
            
            train_loss = train_epoch(model, train_loader, optimizer)
            val_loss = validate(model, val_loader)
            
            print(f"  Train Loss: {train_loss:.4f}")
            print(f"  Val Loss: {val_loss:.4f}")
            
            mlflow.log_metrics({
                "train_loss": train_loss,
                "val_loss": val_loss
            }, step=epoch)
        
        # Save model
        print(f"Saving model to {args.output_dir}")
        save_model(model, tokenizer, args.output_dir)
        
        # Log artefacts
        mlflow.log_artifacts(f"{args.output_dir}/model", artifact_path="model")
        mlflow.log_artifacts(f"{args.output_dir}/tokenizer", artifact_path="tokenizer")
        
        # Register model
        model_uri = f"runs:/{mlflow.active_run().info.run_id}/model"
        registered = mlflow.register_model(model_uri, "planner_model")
        
        print(f"Registered model: planner_model version {registered.version}")
        
        return registered.version


if __name__ == "__main__":
    main()
"""

# -----------------------------------------------------------------------------
# Placeholder - Remove when implementing
# -----------------------------------------------------------------------------

print("This is a template file. Implement the training logic above.")
print("See docs/training-workflow.md for requirements.")

