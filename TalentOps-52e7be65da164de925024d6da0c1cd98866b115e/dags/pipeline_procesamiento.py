import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(__file__)))

from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime

from src.validacion.ventas_validator import validar_datos_ventas
# from src.procesamiento import procesar_datos_rapido


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
    # En un pipeline real, estos datos vendrían de XCom
    datos_ventas = [
        {'precio': 100, 'fecha': '2024-01-01'},
        {'precio': -50, 'fecha': '2024-01-02'}
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

    # ORDEN DEL PIPELINE
    validar >> procesar


dag = dag
