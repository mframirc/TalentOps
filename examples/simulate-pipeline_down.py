from datetime import datetime
from src.incident_response.runbook import IncidentRunbook

if __name__ == "__main__":
    runbook = IncidentRunbook()

    incident_context = {
        "triggered_by": "alert_pipeline_down",
        "affected_components": ["etl_pipeline", "data_warehouse"],
        "start_time": datetime.now(),
        "symptoms": ["scheduler_not_responding", "tasks_queued"],
    }

    response = runbook.handle_incident("pipeline_down", incident_context)

    print("Respuesta a incidente:")
    print(f"Tipo: {response['incident_type']}")
    print(f"Severidad: {response['severity']}")
    print(f"Resuelto: {response['resolved']}")
    print(f"Duración: {response['duration_seconds']:.1f}s")
    print(f"Pasos ejecutados: {len(response['steps_executed'])}")

    for step in response["steps_executed"]:
        status = "✅" if step["success"] else "❌"
        print(f"  {status} {step['step']}")