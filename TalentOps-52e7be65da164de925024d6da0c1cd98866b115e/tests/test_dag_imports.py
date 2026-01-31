import os
from airflow.models import DagBag

def test_dag_imports():
    dag_bag = DagBag(dag_folder=os.path.join(os.getcwd(), "dags"), include_examples=False)
    assert len(dag_bag.import_errors) == 0, f"Errores al importar DAGs: {dag_bag.import_errors}"

