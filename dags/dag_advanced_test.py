# This dag will be used to test: DAG should be installed along with 
# airflow at the time of airflow helm installation.

from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator
from airflow.providers.mysql.operators.mysql import MySqlOperator
from airflow.models.connection import Connection
from airflow.models import Variable
import logging

# Default arguments for the DAG
default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 2,
    'retry_delay': timedelta(minutes=5),
}

# Create the DAG
dag = DAG(
    'advanced_test_dag',
    default_args=default_args,
    description='An advanced test DAG with multiple tasks and MySQL integration',
    schedule_interval=None,
    start_date=datetime(2023, 1, 1),
    catchup=False,
    tags=['test', 'advanced', 'mysql'],
)

# Task 1: Check environment
def check_environment(**kwargs):
    """Check Airflow environment and connections."""
    try:
        # Check if MySQL connection exists
        from airflow.hooks.base import BaseHook
        try:
            conn = BaseHook.get_connection('mysql_default')
            logging.info(f"MySQL connection found: {conn.host}")
            return f"MySQL connection verified: {conn.host}"
        except Exception as e:
            logging.warning(f"MySQL connection not found: {str(e)}")
            return "MySQL connection not found"
    except Exception as e:
        logging.error(f"Error checking environment: {str(e)}")
        return f"Error: {str(e)}"

t1 = PythonOperator(
    task_id='check_environment',
    python_callable=check_environment,
    provide_context=True,
    dag=dag,
)

# Task 2: Create test table if not exists
create_table_sql = """
CREATE TABLE IF NOT EXISTS test_table (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100),
    value INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
"""

t2 = MySqlOperator(
    task_id='create_test_table',
    mysql_conn_id='mysql_default',
    sql=create_table_sql,
    dag=dag,
)

# Task 3: Insert test data
insert_data_sql = """
INSERT INTO test_table (name, value) VALUES 
('test_item_1', 100),
('test_item_2', 200);
"""

t3 = MySqlOperator(
    task_id='insert_test_data',
    mysql_conn_id='mysql_default',
    sql=insert_data_sql,
    dag=dag,
)

# Task 4: Report completion
t4 = BashOperator(
    task_id='report_completion',
    bash_command='echo "Advanced test DAG completed successfully at $(date)"',
    dag=dag,
)

# Define task dependencies
t1 >> t2 >> t3 >> t4 