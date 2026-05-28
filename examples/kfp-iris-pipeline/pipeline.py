#!/usr/bin/env python3
"""
Kubeflow Pipelines v2 demo — Iris classification
================================================
A 3-step DAG pipeline that exercises the full KFP v2 runtime:

  data-prep  →  train  →  evaluate

- data-prep  : downloads the Iris dataset, performs a stratified train/test
               split, persists both splits as Dataset artifacts, and logs
               sample/feature counts as pipeline metrics.
- train      : trains a RandomForest classifier on the training split and
               persists the fitted model as a Model artifact.  The number of
               estimators is a pipeline parameter so every run is reproducible
               and comparable.
- evaluate   : loads the model and test split, computes accuracy, and logs
               the result as a pipeline metric visible in the KFP UI.

Prerequisites
-------------
  pip install kfp>=2.11

Usage
-----
  # 1. Port-forward the ml-pipeline API (or use a real endpoint):
  kubectl port-forward -n kubeflow svc/ml-pipeline 8888:8888 &

  # 2. Run this script:
  python3 pipeline.py

  # 3. Watch progress in the KFP UI:
  kubectl port-forward -n kubeflow svc/ml-pipeline-ui 8080:80 &
  open http://localhost:8080

Expected metrics
----------------
  data-prep : train_samples=120, test_samples=30, features=4
  train     : n_estimators=150
  evaluate  : accuracy=0.9, accuracy_pct=90.0
"""

import warnings
import kfp
from kfp import dsl
from kfp.dsl import Dataset, Model, Metrics, Output, Input

# ---------------------------------------------------------------------------
# Components
# ---------------------------------------------------------------------------

@dsl.component(
    base_image="python:3.11-slim",
    packages_to_install=["scikit-learn==1.4.2", "numpy"],
)
def data_prep(
    train_dataset: Output[Dataset],
    test_dataset:  Output[Dataset],
    metrics:       Output[Metrics],
):
    """Download Iris, split 80/20 stratified, persist as artifacts."""
    import json
    from sklearn.datasets import load_iris
    from sklearn.model_selection import train_test_split

    iris = load_iris()
    X_train, X_test, y_train, y_test = train_test_split(
        iris.data, iris.target,
        test_size=0.2, random_state=42, stratify=iris.target,
    )

    with open(train_dataset.path, "w") as f:
        json.dump({"X": X_train.tolist(), "y": y_train.tolist()}, f)
    with open(test_dataset.path, "w") as f:
        json.dump({"X": X_test.tolist(), "y": y_test.tolist()}, f)

    metrics.log_metric("train_samples", int(len(X_train)))
    metrics.log_metric("test_samples",  int(len(X_test)))
    metrics.log_metric("features",      int(iris.data.shape[1]))
    print(f"Data prepared — train: {len(X_train)}, test: {len(X_test)}, features: {iris.data.shape[1]}")


@dsl.component(
    base_image="python:3.11-slim",
    packages_to_install=["scikit-learn==1.4.2"],
)
def train(
    train_dataset: Input[Dataset],
    model:         Output[Model],
    metrics:       Output[Metrics],
    n_estimators:  int = 100,
):
    """Train a RandomForest on the training split."""
    import json
    import pickle
    from sklearn.ensemble import RandomForestClassifier

    with open(train_dataset.path) as f:
        data = json.load(f)

    clf = RandomForestClassifier(n_estimators=n_estimators, random_state=42)
    clf.fit(data["X"], data["y"])

    with open(model.path, "wb") as f:
        pickle.dump(clf, f)

    metrics.log_metric("n_estimators", n_estimators)
    print(f"Trained RandomForest with {n_estimators} estimators on {len(data['X'])} samples")


@dsl.component(
    base_image="python:3.11-slim",
    packages_to_install=["scikit-learn==1.4.2"],
)
def evaluate(
    test_dataset: Input[Dataset],
    model:        Input[Model],
    metrics:      Output[Metrics],
):
    """Evaluate model accuracy and log a per-class report."""
    import json
    import pickle
    from sklearn.metrics import accuracy_score, classification_report

    with open(test_dataset.path) as f:
        data = json.load(f)
    with open(model.path, "rb") as f:
        clf = pickle.load(f)

    preds = clf.predict(data["X"])
    acc   = accuracy_score(data["y"], preds)

    metrics.log_metric("accuracy",     round(acc, 4))
    metrics.log_metric("accuracy_pct", round(acc * 100, 2))

    print(f"Test accuracy: {acc * 100:.2f}%")
    print(classification_report(
        data["y"], preds,
        target_names=["setosa", "versicolor", "virginica"],
    ))


# ---------------------------------------------------------------------------
# Pipeline
# ---------------------------------------------------------------------------

@dsl.pipeline(
    name="iris-classification-demo",
    description="Iris data prep → RandomForest train → evaluate (KFP v2 demo)",
)
def iris_pipeline(n_estimators: int = 100):
    prep_task  = data_prep()
    train_task = train(
        train_dataset=prep_task.outputs["train_dataset"],
        n_estimators=n_estimators,
    )
    evaluate(
        test_dataset=prep_task.outputs["test_dataset"],
        model=train_task.outputs["model"],
    )


# ---------------------------------------------------------------------------
# Submit
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    warnings.filterwarnings("ignore", category=FutureWarning)

    KFP_ENDPOINT = "http://localhost:8888"

    client = kfp.Client(host=KFP_ENDPOINT)

    run = client.create_run_from_pipeline_func(
        iris_pipeline,
        arguments={"n_estimators": 150},
        run_name="iris-demo-run",
        enable_caching=False,
    )

    print(f"Submitted run : {run.run_id}")
    print(f"UI (port-fwd) : {KFP_ENDPOINT}/#/runs/details/{run.run_id}")
    print()
    print("Poll for completion:")
    print(f"  python3 -c \"import kfp,warnings; warnings.filterwarnings('ignore'); "
          f"c=kfp.Client(host='{KFP_ENDPOINT}'); "
          f"r=c.wait_for_run_completion('{run.run_id}', timeout=600); "
          f"print('state:', r.state)\"")
