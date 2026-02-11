import argparse
import os
import pandas as pd
import mlflow
import mlflow.sklearn  # Using sklearn as a placeholder for a "model"
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import train_test_split

def parse_args():
    parser = argparse.ArgumentParser(description="Train planner model")
    
    # Dataset
    parser.add_argument("--dataset", default="../datasets/example_ml/training.parquet", help="Path to dataset file")
    
    # Model
    parser.add_argument("--model_base", default="dummy-base-model", help="Base model name")
    
    # Training hyperparameters
    parser.add_argument("--epochs", type=int, default=3)
    parser.add_argument("--lr", type=float, default=1e-4)
    parser.add_argument("--batch_size", type=int, default=16)
    
    # Output
    parser.add_argument("--output_dir", default="./output")
    
    return parser.parse_args()

def load_dataset(dataset_path):
    """Load training dataset from parquet files."""
    if not os.path.exists(dataset_path):
        # Create dummy data if not exists for skeleton functionality
        print(f"Dataset {dataset_path} not found. Creating dummy data.")
        df = pd.DataFrame({
            'feature1': [1, 2, 3, 4, 5] * 20,
            'feature2': [5, 4, 3, 2, 1] * 20,
            'target': [0, 1, 0, 1, 0] * 20
        })
        os.makedirs(os.path.dirname(dataset_path), exist_ok=True)
        df.to_parquet(dataset_path)
    
    df = pd.read_parquet(dataset_path)
    train_set, val_set = train_test_split(df, test_size=0.2)
    return train_set, val_set

def main():
    args = parse_args()
    
    # Set MLflow tracking URI (local by default)
    # mlflow.set_tracking_uri("http://localhost:5000") 
    
    # Initialize MLflow
    mlflow.set_experiment("planner_training")
    
    with mlflow.start_run():
        # Log parameters
        mlflow.log_params({
            "learning_rate": args.lr,
            "batch_size": args.batch_size,
            "epochs": args.epochs,
            "dataset_path": args.dataset,
            "model_base": args.model_base
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
        
        # Mock Training Loop
        print("Starting training...")
        # In a real scenario, this would be a PyTorch/HuggingFace loop
        # For the skeleton, we'll use a simple scikit-learn model
        X_train = train_set.drop('target', axis=1)
        y_train = train_set['target']
        X_val = val_set.drop('target', axis=1)
        y_val = val_set['target']
        
        model = LogisticRegression()
        model.fit(X_train, y_train)
        
        # Log metrics
        for epoch in range(args.epochs):
            # Simulate improving loss
            train_loss = 0.5 / (epoch + 1)
            val_loss = 0.6 / (epoch + 1)
            
            mlflow.log_metrics({
                "train_loss": train_loss,
                "val_loss": val_loss
            }, step=epoch)
            
        val_acc = model.score(X_val, y_val)
        mlflow.log_metric("val_accuracy", val_acc)
        
        # Save and Register model
        print("Registering model...")
        mlflow.sklearn.log_model(
            sk_model=model,
            artifact_path="model",
            registered_model_name="planner_model"
        )
        
        print("Training complete. Model registered as 'planner_model'.")

if __name__ == "__main__":
    main()
