{
 "cells": [
  {
   "cell_type": "code",
   "execution_count": null,
   "id": "b3052a88",
   "metadata": {},
   "outputs": [],
   "source": [
    "# dags/mi_primer_dag.py\n",
    "from airflow import DAG\n",
    "from airflow.operators.bash import BashOperator\n",
    "from airflow.operators.python import PythonOperator\n",
    "from datetime import datetime, timedelta\n",
    "\n",
    "def saludar():\n",
    "    print(\"¡Hola desde Airflow!\")\n",
    "    return \"Saludo completado\"\n",
    "\n",
    "# Definir DAG\n",
    "dag = DAG(\n",
    "    'saludo_diario',\n",
    "    description='DAG que saluda cada día',\n",
    "    schedule_interval=timedelta(days=1),  # Ejecutar diariamente\n",
    "    start_date=datetime(2024, 1, 1),\n",
    "    catchup=False,  # No ejecutar ejecuciones pasadas\n",
    "    tags=['ejemplo', 'saludo']\n",
    ")\n",
    "\n",
    "# Tarea 1: Comando bash\n",
    "tarea_bash = BashOperator(\n",
    "    task_id='tarea_bash',\n",
    "    bash_command='echo \"Ejecutando tarea bash a las $(date)\"',\n",
    "    dag=dag\n",
    ")\n",
    "\n",
    "# Tarea 2: Función Python\n",
    "tarea_python = PythonOperator(\n",
    "    task_id='tarea_python',\n",
    "    python_callable=saludar,\n",
    "    dag=dag\n",
    ")\n",
    "\n",
    "# Tarea 3: Esperar (simular procesamiento)\n",
    "tarea_esperar = BashOperator(\n",
    "    task_id='tarea_esperar',\n",
    "    bash_command='sleep 5',\n",
    "    dag=dag\n",
    ")\n",
    "\n",
    "# Definir orden de ejecución\n",
    "tarea_bash >> tarea_python >> tarea_esperar"
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "Python 3 (ipykernel)",
   "language": "python",
   "name": "python3"
  },
  "language_info": {
   "codemirror_mode": {
    "name": "ipython",
    "version": 3
   },
   "file_extension": ".py",
   "mimetype": "text/x-python",
   "name": "python",
   "nbconvert_exporter": "python",
   "pygments_lexer": "ipython3",
   "version": "3.11.7"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 5
}
