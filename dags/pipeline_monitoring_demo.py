from airflow import DAG
from airflow.operators.python import PythonOperator
# from airflow.metrics import Stats   # ❌ Eliminado: Airflow 2.9 ya no lo soporta
from datetime import datetime, timedelta
import logging

logger = logging.getLogger(__name__)

# -----------------------------
# EXTRACT
# -----------------------------
def extract_with_metrics(**context):
    """Extracción simulada sin Stats (Airflow 2.9)"""
    try:
        records = 1000
        duration = 45.2  # segundos

        # Logs estructurados (mantienen trazabilidad)
        logger.info(
            f"Extract completed: {records} records in {duration}s",
            extra={'records': records, 'duration': duration}
        )

        return {'records': records, 'duration': duration}

    except Exception as e:
        logger.error(f"Extract failed: {e}")
        raise e

# -----------------------------
# TRANSFORM
# -----------------------------
def transform_with_metrics(**context):
    """Transformación simulada sin Stats"""
    ti = context['task_instance']
    input_data = ti.xcom_pull(task_ids='extract')

    try:
        output_records = input_data['records'] * 0.95
        quality_score = 0.98

        if quality_score < 0.9:
            logger.warning(f"Low quality score: {quality_score}")

        return {'output_records': output_records, 'quality': quality_score}

    except Exception as e:
        logger.error(f"Transform failed: {e}")
        raise e

# -----------------------------
# LOAD
# -----------------------------
def load_with_metrics(**context):
    """Carga simulada sin Stats"""
    ti = context['task_instance']
    transform_data = ti.xcom_pull(task_ids='transform')

    try:
        records_loaded = transform_data['output_records']
        load_time = 12.5

        throughput = records_loaded / load_time
        logger.info(
            f"Load completed: {records_loaded} records in {load_time}s "
            f"(throughput={throughput})"
        )

        return {'loaded': records_loaded, 'throughput': throughput}

    except Exception as e:
        logger.error(f"Load failed: {e}")
        raise e

# -----------------------------
# CALLBACKS
# -----------------------------
def dag_success_callback(context):
    dag_run = context['dag_run']
    duration = (dag_run.end_date - dag_run.start_date).total_seconds()

    logger.info(f"DAG completed successfully in {duration}s")

def dag_failure_callback(context):
    logger.error(f"DAG failed: {context['dag'].dag_id}")

def sla_miss_callback(dag, task_list, blocking_task_list, slas, blocking_tis):
    logger.warning(f"SLA missed for DAG: {dag.dag_id}")

# -----------------------------
# DAG CONFIG
# -----------------------------
dag = DAG(
    'pipeline_monitoring_demo',
    description='Pipeline con monitoreo sin Stats (compatible Airflow 2.9)',
    schedule_interval='@daily',
    start_date=datetime(2024, 1, 1),
    catchup=False,
    default_args={
        'retries': 2,
        'retry_delay': timedelta(minutes=5),
        'execution_timeout': timedelta(hours=2),
        'sla': timedelta(hours=1)
    },
    on_success_callback=dag_success_callback,
    on_failure_callback=dag_failure_callback,
    sla_miss_callback=sla_miss_callback,
    tags=['monitoring', 'production']
)

# -----------------------------
# TASKS
# -----------------------------
extract_task = PythonOperator(
    task_id='extract',
    python_callable=extract_with_metrics,
    provide_context=True,
    dag=dag
)

transform_task = PythonOperator(
    task_id='transform',
    python_callable=transform_with_metrics,
    provide_context=True,
    dag=dag
)

load_task = PythonOperator(
    task_id='load',
    python_callable=load_with_metrics,
    provide_context=True,
    dag=dag
)

# Dependencias
extract_task >> transform_task >> load_task