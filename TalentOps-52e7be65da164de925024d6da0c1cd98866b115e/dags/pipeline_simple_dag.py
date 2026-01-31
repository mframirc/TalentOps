from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime, timedelta

# -----------------------------
# Funciones del pipeline
# -----------------------------

def paso_1():
    print("Ejecutando paso_1: Capturar datos de API")
    return {"valor": 42}

def paso_2(**context):
    print("Ejecutando paso_2: Validar y limpiar datos")
    data = context["ti"].xcom_pull(task_ids="paso_1")
    if not data or "valor" not in data:
        raise ValueError("Error de validación: datos incompletos")
    print("Datos validados correctamente")

def paso_3(**context):
    print("Ejecutando paso_3: Guardar en base de datos")
    data = context["ti"].xcom_pull(task_ids="paso_2")
    print(f"Guardando datos: {data}")

# -----------------------------
# Definición del DAG
# -----------------------------

default_args = {
    "owner": "mauricio",
    "retries": 1,
    "retry_delay": timedelta(seconds=10),
}

with DAG(
    dag_id="pipeline_simple",
    start_date=datetime(2024, 1, 1),
    schedule_interval="@daily",
    catchup=False,
    default_args=default_args,
) as dag:

    t1 = PythonOperator(
        task_id="paso_1",
        python_callable=paso_1,
    )

    t2 = PythonOperator(
        task_id="paso_2",
        python_callable=paso_2,
        provide_context=True,
    )

    t3 = PythonOperator(
        task_id="paso_3",
        python_callable=paso_3,
        provide_context=True,
    )

    t1 >> t2 >> t3
