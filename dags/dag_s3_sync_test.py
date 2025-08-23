# This DAG demonstrates the use of the s3_sync operator in Airflow.
# Upload this dag to s3 should sync this dag automatically in Airflow.

from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator

# Default arguments for the DAG
default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

# Create the DAG
dag = DAG(
    's3_sync_test',
    default_args=default_args,
    description='A test DAG to verify S3 to Airflow sync',
    schedule_interval=None,
    start_date=datetime(2023, 1, 1),
    catchup=False,
    tags=['test', 's3', 'sync'],
)

def print_execution_date(**kwargs):
    """Print the execution date of the DAG."""
    print(f"Execution date: {kwargs['execution_date']}")
    return f"Execution date: {kwargs['execution_date']}"

# Task to print the execution date
t1 = PythonOperator(
    task_id='print_execution_date',
    python_callable=print_execution_date,
    provide_context=True,
    dag=dag,
)

# Task to print a message
t2 = BashOperator(
    task_id='print_message',
    bash_command='echo "This DAG was successfully synced from S3!"',
    dag=dag,
)

# Define task dependencies
t1 >> t2 