from typing import Dict, List, Callable
from datetime import datetime, timedelta
import logging

logger = logging.getLogger("incident_response")
logging.basicConfig(level=logging.INFO)


class IncidentRunbook:
    """Runbook automatizado para respuesta a incidentes"""

    def __init__(self):
        self.incident_types = self._define_incident_types()
        self.escalation_matrix = self._define_escalation()

    def _define_incident_types(self) -> Dict:
        return {
            "pipeline_down": {
                "severity": "CRITICAL",
                "auto_response": True,
                "timeout": timedelta(minutes=15),
                "steps": [
                    "check_airflow_scheduler",
                    "check_database_connectivity",
                    "restart_failed_services",
                    "verify_pipeline_recovery",
                ],
            },
            "data_quality_degraded": {
                "severity": "HIGH",
                "auto_response": False,
                "timeout": timedelta(hours=1),
                "steps": [
                    "isolate_affected_data",
                    "check_upstream_sources",
                    "implement_data_filters",
                    "notify_data_consumers",
                ],
            },
            "performance_degraded": {
                "severity": "MEDIUM",
                "auto_response": True,
                "timeout": timedelta(hours=2),
                "steps": [
                    "check_resource_usage",
                    "scale_resources_if_needed",
                    "optimize_running_queries",
                    "monitor_recovery",
                ],
            },
        }

    def _define_escalation(self) -> Dict:
        return {
            "CRITICAL": {
                "5min": "alert_lead_engineer",
                "15min": "alert_engineering_manager",
                "30min": "alert_vp_engineering",
            },
            "HIGH": {
                "15min": "alert_lead_engineer",
                "45min": "alert_engineering_manager",
            },
            "MEDIUM": {
                "30min": "alert_lead_engineer",
                "2h": "alert_engineering_manager",
            },
        }

    def handle_incident(self, incident_type: str, context: Dict) -> Dict:
        if incident_type not in self.incident_types:
            return {"status": "unknown_incident_type"}

        incident_config = self.incident_types[incident_type]
        start_time = datetime.now()

        logger.info(
            f"Handling {incident_type} incident "
            f"(severity: {incident_config['severity']})"
        )

        results = {
            "incident_type": incident_type,
            "severity": incident_config["severity"],
            "start_time": start_time.isoformat(),
            "steps_executed": [],
            "auto_recovery_attempted": incident_config["auto_response"],
        }

        for step in incident_config["steps"]:
            step_result = self._execute_step(step, context)
            results["steps_executed"].append(step_result)

            if step_result["success"]:
                logger.info(f"Step {step} completed successfully")
            else:
                logger.error(f"Step {step} failed: {step_result.get('error')}")
                break

        end_time = datetime.now()
        results["resolved"] = self._verify_resolution(incident_type, context)
        results["end_time"] = end_time.isoformat()
        results["duration_seconds"] = (end_time - start_time).total_seconds()

        if not results["resolved"]:
            self._escalate_incident(
                incident_config["severity"], results["duration_seconds"]
            )

        return results

    def _execute_step(self, step_name: str, context: Dict) -> Dict:
        step_functions: Dict[str, Callable[[], Dict]] = {
            "check_airflow_scheduler": lambda: self._check_service(
                "airflow-scheduler"
            ),
            "check_database_connectivity": self._check_database_connection,
            "restart_failed_services": lambda: self._restart_services(
                ["airflow-scheduler", "airflow-webserver"]
            ),
            "verify_pipeline_recovery": self._verify_pipeline_status,
            "isolate_affected_data": self._isolate_bad_data,
            "check_resource_usage": self._check_system_resources,
            "scale_resources_if_needed": self._scale_resources,
        }

        try:
            step_func = step_functions.get(step_name)
            if step_func:
                result = step_func()
                return {"step": step_name, "success": True, "result": result}
            else:
                return {
                    "step": step_name,
                    "success": False,
                    "error": "Step not implemented",
                }
        except Exception as e:
            return {"step": step_name, "success": False, "error": str(e)}

    def _escalate_incident(self, severity: str, duration_seconds: float):
        escalation_rules = self.escalation_matrix.get(severity, {})
        for time_threshold, action in escalation_rules.items():
            threshold_seconds = self._parse_time_to_seconds(time_threshold)
            if duration_seconds >= threshold_seconds:
                logger.warning(f"Escalating {severity} incident: {action}")

    # --------- Funciones auxiliares simuladas ---------

    def _check_service(self, service_name: str) -> Dict:
        return {"status": "running", "pid": 12345, "service": service_name}

    def _check_database_connection(self) -> Dict:
        return {"connected": True, "latency_ms": 15}

    def _restart_services(self, services: List[str]) -> Dict:
        return {"restarted": services, "status": "success"}

    def _verify_pipeline_status(self) -> Dict:
        return {"pipelines_running": 5, "pipelines_failed": 0}

    def _isolate_bad_data(self) -> Dict:
        return {"isolated_records": 150, "quarantined": True}

    def _check_system_resources(self) -> Dict:
        return {
            "cpu_percent": 45,
            "memory_percent": 60,
            "disk_percent": 30,
        }

    def _scale_resources(self) -> Dict:
        return {"scaled_up": ["airflow-worker"], "new_instances": 2}

    def _verify_resolution(self, incident_type: str, context: Dict) -> bool:
        return True

    def _parse_time_to_seconds(self, time_str: str) -> int:
        if "min" in time_str:
            return int(time_str.replace("min", "")) * 60
        if "h" in time_str:
            return int(time_str.replace("h", "")) * 3600
        return 0