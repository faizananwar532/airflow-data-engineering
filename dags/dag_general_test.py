"""
General Test DAG

This DAG provides general testing capabilities for Airflow:
1. Basic Python operations
2. File system operations
3. Environment checks
4. Simple data processing

Author: Airflow Data Engineering
"""

from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from airflow.operators.dummy import DummyOperator
import logging
import os
import sys

# Default arguments
default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

# DAG definition
dag = DAG(
    'general_test',
    default_args=default_args,
    description='General purpose test DAG for Airflow',
    schedule_interval=timedelta(days=1),
    catchup=False,
    tags=['test', 'general', 'utilities'],
)

def environment_check():
    """
    Check Airflow environment and system information
    """
    logging.info("🔍 Checking Airflow environment...")
    
    # Python version
    logging.info(f"Python version: {sys.version}")
    
    # Environment variables
    airflow_home = os.environ.get('AIRFLOW_HOME', 'Not set')
    logging.info(f"AIRFLOW_HOME: {airflow_home}")
    
    # Working directory
    working_dir = os.getcwd()
    logging.info(f"Working directory: {working_dir}")
    
    # Available modules
    logging.info("Available Python modules:")
    for module in ['pandas', 'numpy', 'requests', 'mysql']:
        try:
            __import__(module)
            logging.info(f"✅ {module} - Available")
        except ImportError:
            logging.info(f"❌ {module} - Not available")
    
    return "Environment check completed"

def file_operations():
    """
    Test basic file operations
    """
    logging.info("📁 Testing file operations...")
    
    # Create a test file
    test_file = "/tmp/airflow_test.txt"
    with open(test_file, 'w') as f:
        f.write(f"Airflow test file created at {datetime.now()}\n")
        f.write("This is a test file for Airflow operations.\n")
    
    logging.info(f"Created test file: {test_file}")
    
    # Read the file back
    with open(test_file, 'r') as f:
        content = f.read()
        logging.info(f"File content: {content}")
    
    # Clean up
    os.remove(test_file)
    logging.info("Test file cleaned up")
    
    return "File operations test completed"

def data_processing():
    """
    Test basic data processing capabilities
    """
    logging.info("📊 Testing data processing...")
    
    # Simple data processing
    data = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    
    # Calculate statistics
    total = sum(data)
    average = total / len(data)
    maximum = max(data)
    minimum = min(data)
    
    logging.info(f"Data: {data}")
    logging.info(f"Total: {total}")
    logging.info(f"Average: {average}")
    logging.info(f"Maximum: {maximum}")
    logging.info(f"Minimum: {minimum}")
    
    # Simple data transformation
    squared_data = [x**2 for x in data]
    logging.info(f"Squared data: {squared_data}")
    
    return "Data processing test completed"

def airflow_info():
    """
    Display Airflow information
    """
    logging.info("🚀 Airflow Information:")
    logging.info(f"DAG ID: {dag.dag_id}")
    logging.info(f"Start Date: {dag.start_date}")
    logging.info(f"Schedule Interval: {dag.schedule_interval}")
    logging.info(f"Tags: {dag.tags}")
    
    return "Airflow info displayed"

# Task definitions
start_task = DummyOperator(
    task_id='start',
    dag=dag,
)

environment_task = PythonOperator(
    task_id='environment_check',
    python_callable=environment_check,
    dag=dag,
)

file_ops_task = PythonOperator(
    task_id='file_operations',
    python_callable=file_operations,
    dag=dag,
)

data_processing_task = PythonOperator(
    task_id='data_processing',
    python_callable=data_processing,
    dag=dag,
)

airflow_info_task = PythonOperator(
    task_id='airflow_info',
    python_callable=airflow_info,
    dag=dag,
)

bash_task = BashOperator(
    task_id='bash_test',
    bash_command='echo "Bash operator test successful!" && date && whoami',
    dag=dag,
)

end_task = DummyOperator(
    task_id='end',
    dag=dag,
)

# Task dependencies
start_task >> environment_task >> [file_ops_task, data_processing_task] >> airflow_info_task >> bash_task >> end_task
