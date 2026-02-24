import pytest
from airflow.models import DagBag
from airflow.operators.python import PythonOperator
from datetime import datetime, timedelta


class TestETLPipeline:

    @pytest.fixture(scope="class")
    def dagbag(self):
        return DagBag(include_examples=False)

    def test_dag_loaded(self, dagbag):
        dag = dagbag.get_dag("etl_pipeline")
        assert dag is not None, "DAG etl_pipeline no encontrado"
        assert dag.description, "El DAG debe tener descripción"

    def test_dag_structure(self, dagbag):
        dag = dagbag.get_dag("etl_pipeline")
        assert len(dag.tasks) >= 5, f"DAG tiene solo {len(dag.tasks)} tareas"

        task_ids = [t.task_id for t in dag.tasks]
        for required in ["extract", "transform", "load"]:
            assert required in task_ids, f"Tarea obligatoria faltante: {required}"

    def test_unique_task_ids(self, dagbag):
        dag = dagbag.get_dag("etl_pipeline")
        task_ids = [t.task_id for t in dag.tasks]
        assert len(task_ids) == len(set(task_ids)), "Hay task_ids duplicados"

    def test_dag_dependencies(self, dagbag):
        dag = dagbag.get_dag("etl_pipeline")

        extract = dag.get_task("extract")
        transform = dag.get_task("transform")
        load = dag.get_task("load")

        assert transform in extract.downstream_list, "transform debe depender de extract"
        assert load in transform.downstream_list, "load debe depender de transform"

    def test_default_args(self, dagbag):
        dag = dagbag.get_dag("etl_pipeline")
        args = dag.default_args

        assert args.get("owner") == "data-engineering", "owner incorrecto"
        assert args.get("retries") >= 1, "retries debe ser >= 1"
        assert args.get("retry_delay") >= timedelta(minutes=1), "retry_delay muy bajo"

    def test_dag_schedule(self, dagbag):
        dag = dagbag.get_dag("etl_pipeline")

        assert dag.schedule_interval is not None, "DAG sin schedule"
        assert dag.start_date is not None, "DAG sin start_date"
        assert dag.start_date < datetime.now(), "start_date no puede ser futuro"

    def test_dag_tags(self, dagbag):
        dag = dagbag.get_dag("etl_pipeline")
        required = {"etl", "sales"}
        assert required.issubset(set(dag.tags)), f"Faltan tags: {required}"

    def test_task_configuration(self, dagbag):
        dag = dagbag.get_dag("etl_pipeline")

        for task in dag.tasks:
            assert task.retries >= 1, f"Tarea {task.task_id} sin retries"

            if getattr(task, "execution_timeout", None):
                assert task.execution_timeout <= timedelta(hours=2), (
                    f"Timeout excesivo en {task.task_id}"
                )

    def test_tasks_have_documentation(self, dagbag):
        dag = dagbag.get_dag("etl_pipeline")

        for task in dag.tasks:
            assert task.doc_md is not None, f"Tarea {task.task_id} sin documentación"

    def test_template_rendering(self, dagbag):
        dag = dagbag.get_dag("etl_pipeline")

        for task in dag.tasks:
            for field in getattr(task, "template_fields", []):
                getattr(task, field)

    def test_python_operator_callable(self, dagbag):
        dag = dagbag.get_dag("etl_pipeline")

        for task in dag.tasks:
            if isinstance(task, PythonOperator):
                assert callable(task.python_callable), (
                    f"PythonOperator {task.task_id} sin callable válido"
                )