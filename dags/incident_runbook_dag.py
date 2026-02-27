from datetime import datetime
from airflow import DAG
from airflow.operators.python import PythonOperator

# Importar el runbook desde tu proyecto TalentOps
from src.incident_response.runbook import IncidentRunbook


def ejecutar_runbook():
    runbook = IncidentRunbook()

    incident_context = {
        "triggered_by": "airflow_dag",
        "affected_components": ["etl_pipeline", "data_warehouse"],
        "start_time": datetime.now(),
        "symptoms": ["scheduler_not_responding", "tasks_queued"],
    }

    response = runbook.handle_incident("pipeline_down", incident_context)

    print("=== RESULTADO DEL RUNBOOK ===")
    print(f"Tipo: {response['incident_type']}")
    print(f"Severidad: {response['severity']}")
    print(f"Resuelto: {response['resolved']}")
    print(f"Duración: {response['duration_seconds']:.1f}s")
    print("Pasos ejecutados:")

    for step in response["steps_executed"]:
        status = "OK" if step["success"] else "FAIL"
        print(f" - {step['step']} [{status}]")

    return response


with DAG(
    dag_id="incident_runbook_dag",
    start_date=datetime(2024, 1, 1),
    schedule_interval=None,  # Se ejecuta manualmente
    catchup=False,
    tags=["incident_response", "runbook"],
) as dag:

    ejecutar_incidente = PythonOperator(
        task_id="ejecutar_runbook_incidente",
        python_callable=ejecutar_runbook,
    )