from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime
import logging

from src.validacion.ventas.validador import validar_datos_ventas
from src.incident_response.runbook import IncidentRunbook


logger = logging.getLogger(__name__)


# -----------------------------
# CALLBACK DE FALLO (RUNBOOK)
# -----------------------------
def on_failure_callback(context):
    dag_id = context["dag"].dag_id
    task_id = context["task_instance"].task_id
    error = context["exception"]

    runbook = IncidentRunbook()

    incident_context = {
        "triggered_by": "airflow_failure",
        "dag_id": dag_id,
        "task_id": task_id,
        "error": str(error)
    }

    response = runbook.handle_incident("pipeline_down", incident_context)

    logger.error(f"Runbook ejecutado por fallo en {dag_id}.{task_id}: {response}")


# -----------------------------
# TAREA DE PROCESAMIENTO
# -----------------------------
def tarea_procesamiento():
    datos_prueba = [{'precio': i, 'cantidad': i % 10} for i in range(1000)]
    resultado = [{'total': d['precio'] * d['cantidad']} for d in datos_prueba]
    print(f"Procesados {len(resultado)} registros")


# -----------------------------
# TAREA DE VALIDACIÓN
# -----------------------------
def tarea_validar_datos(**context):
    datos_ventas = [
        {'precio': 100, 'fecha': '2024-01-01'},
        {'precio': -50, 'fecha': '2024-01-02'}  # Esto generará error
    ]

    resultado = validar_datos_ventas(datos_ventas)

    if not resultado['valido']:
        raise ValueError(f"Errores de validación: {resultado['errores']}")

    print("Validación completada correctamente")
    return resultado


# -----------------------------
# DEFINICIÓN DEL DAG
# -----------------------------
with DAG(
    dag_id="pipeline_procesamiento",
    start_date=datetime(2024, 1, 1),
    schedule="@daily",
    catchup=False,
    on_failure_callback=on_failure_callback,
    tags=["processing"]
) as dag:

    validar = PythonOperator(
        task_id="validar_datos_ventas",
        python_callable=tarea_validar_datos,
        provide_context=True,
    )

    procesar = PythonOperator(
        task_id="procesar_datos",
        python_callable=tarea_procesamiento,
    )

    validar >> procesar


dag = dag