import pytest
from airflow.models import DagBag


class TestDAGIntegration:

    @pytest.fixture(scope="class")
    def dagbag(self):
        return DagBag(include_examples=False)

    def test_dag_runs_without_errors(self, dagbag):
        dag = dagbag.get_dag("etl_pipeline")

        assert dag.test_cycle(), "El DAG tiene ciclos de dependencias"

        for task in dag.tasks:
            for upstream in task.upstream_list:
                assert upstream in dag.tasks, (
                    f"Dependencia inválida: {upstream.task_id}"
                )