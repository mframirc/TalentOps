from airflow import DAG
from airflow.operators.empty import EmptyOperator
from airflow.operators.python import PythonOperator, BranchPythonOperator
from airflow.utils.task_group import TaskGroup
from datetime import datetime

# -----------------------------
# Funciones Python
# -----------------------------
def validar_calidad_fn():
    print("Validando calidad de datos...")

def decidir_ruta_fn():
    # Lógica de ejemplo: siempre va por la ruta pesada
    return "procesamiento.procesamiento_pesado"

def procesamiento_rapido_fn():
    print("Procesamiento rápido ejecutado")

def procesamiento_pesado_fn():
    print("Procesamiento pesado ejecutado")

def procesamiento_completo_fn():
    print("Procesamiento completo ejecutado")

def cargar_postgres_fn():
    print("Cargando datos limpios a PostgreSQL...")

def generar_dashboard_fn():
    print("Actualizando dashboard de ventas...")

def enviar_reporte_fn():
    print("Enviando reporte diario...")

# -----------------------------
# Definición del DAG
# -----------------------------
with DAG(
    dag_id="arquitectura_retail_completa",
    start_date=datetime(2024, 1, 1),
    schedule="@daily",
    catchup=False,
    description="Pipeline completo basado en arquitectura retail"
) as dag:

    inicio = EmptyOperator(task_id="inicio")

    # -----------------------------
    # INGESTA
    # -----------------------------
    with TaskGroup("ingesta") as ingesta:
        api_ventas = PythonOperator(
            task_id="api_ventas",
            python_callable=lambda: print("Extrayendo ventas desde API...")
        )
        inventario = PythonOperator(
            task_id="inventario",
            python_callable=lambda: print("Extrayendo inventario desde BD...")
        )

    # -----------------------------
    # PROCESAMIENTO
    # -----------------------------
    with TaskGroup("procesamiento") as procesamiento:

        validar_calidad = PythonOperator(
            task_id="validar_calidad",
            python_callable=validar_calidad_fn
        )

        decidir_ruta = BranchPythonOperator(
            task_id="decidir_ruta",
            python_callable=decidir_ruta_fn
        )

        procesamiento_rapido = PythonOperator(
            task_id="procesamiento_rapido",
            python_callable=procesamiento_rapido_fn
        )

        procesamiento_pesado = PythonOperator(
            task_id="procesamiento_pesado",
            python_callable=procesamiento_pesado_fn
        )

        procesamiento_completo = PythonOperator(
            task_id="procesamiento_completo",
            python_callable=procesamiento_completo_fn
        )

        union_rutas = EmptyOperator(task_id="union_rutas")

        validar_calidad >> decidir_ruta
        decidir_ruta >> [
            procesamiento_rapido,
            procesamiento_pesado,
            procesamiento_completo
        ]
        [
            procesamiento_rapido,
            procesamiento_pesado,
            procesamiento_completo
        ] >> union_rutas

    # -----------------------------
    # ALMACENAMIENTO
    # -----------------------------
    with TaskGroup("almacenamiento") as almacenamiento:
        cargar_postgres = PythonOperator(
            task_id="cargar_postgres",
            python_callable=cargar_postgres_fn
        )

    # -----------------------------
    # CONSUMO
    # -----------------------------
    with TaskGroup("consumo") as consumo:
        dashboard = PythonOperator(
            task_id="dashboard",
            python_callable=generar_dashboard_fn
        )
        reporte = PythonOperator(
            task_id="reporte",
            python_callable=enviar_reporte_fn
        )

    fin = EmptyOperator(task_id="fin")

    # -----------------------------
    # Dependencias finales
    # -----------------------------
    inicio >> ingesta >> procesamiento
    union_rutas >> cargar_postgres
    cargar_postgres >> [dashboard, reporte]
    [dashboard, reporte] >> fin
