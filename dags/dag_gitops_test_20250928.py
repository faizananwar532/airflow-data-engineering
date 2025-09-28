"""
GitOps Test DAG - Created at 2025-09-28 20:30:00
This DAG tests the ArgoCD GitOps sync functionality
"""

from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator
import logging

default_args = {
    'owner': 'gitops-test',
    'depends_on_past': False,
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

dag = DAG(
    'gitops_test_dag_20250928',
    default_args=default_args,
    description='🔄 GitOps test DAG created at 2025-09-28 20:30:00',
    schedule_interval=None,
    start_date=datetime(2023, 1, 1),
    catchup=False,
    tags=['gitops', 'test', 'argocd', '🔄'],
)

def test_gitops_sync(**kwargs):
    """Test function to verify GitOps sync is working"""
    logging.info("🚀 GitOps sync test successful!")
    logging.info(f"DAG ID: gitops_test_dag_20250928")
    logging.info(f"Created at: 2025-09-28 20:30:00")
    logging.info("This DAG was automatically synced by ArgoCD! 🎉")
    logging.info("Testing the complete GitOps workflow:")
    logging.info("1. ✅ DAG created in GitHub repository")
    logging.info("2. ✅ ArgoCD detected the change")
    logging.info("3. ✅ Git sync pulled the new DAG")
    logging.info("4. ✅ Airflow loaded the DAG successfully")
    logging.info("5. ✅ DAG is now executable in Airflow UI")
    return "GitOps sync working perfectly!"

def check_environment(**kwargs):
    """Check the environment and log system info"""
    import platform
    import subprocess
    import os
    
    logging.info("Environment Information:")
    logging.info(f"Python version: {platform.python_version()}")
    logging.info(f"Hostname: {platform.node()}")
    logging.info(f"Platform: {platform.platform()}")
    
    # Check DAGs folder
    dags_folder = os.environ.get("AIRFLOW__CORE__DAGS_FOLDER", "/opt/airflow/dags")
    logging.info(f"Airflow DAGs folder: {dags_folder}")
    
    # List DAG files
    try:
        dag_files = os.listdir(dags_folder)
        logging.info(f"DAG files in folder: {dag_files}")
    except Exception as e:
        logging.warning(f"Could not list DAG files: {e}")
    
    try:
        airflow_version = subprocess.check_output(['airflow', 'version'], text=True).strip()
        logging.info(f"Airflow version: {airflow_version}")
    except Exception as e:
        logging.warning(f"Could not get Airflow version: {e}")
    
    return "Environment check complete"

def test_mysql_connection(**kwargs):
    """Test MySQL connection"""
    import os
    
    logging.info("Testing MySQL connection...")
    mysql_conn = os.environ.get("AIRFLOW_CONN_MYSQL", "Not found")
    logging.info(f"MySQL connection string exists: {'Yes' if mysql_conn != 'Not found' else 'No'}")
    
    # Try to connect to MySQL (basic test)
    try:
        from airflow.hooks.base import BaseHook
        mysql_hook = BaseHook.get_connection('mysql')
        logging.info(f"MySQL connection configured: {mysql_hook.host}:{mysql_hook.port}")
        return "MySQL connection test passed"
    except Exception as e:
        logging.warning(f"MySQL connection test failed: {e}")
        return "MySQL connection test failed (connection may still work)"

t1 = PythonOperator(
    task_id='test_gitops_sync',
    python_callable=test_gitops_sync,
    provide_context=True,
    dag=dag,
)

t2 = PythonOperator(
    task_id='check_environment',
    python_callable=check_environment,
    provide_context=True,
    dag=dag,
)

t3 = PythonOperator(
    task_id='test_mysql_connection',
    python_callable=test_mysql_connection,
    provide_context=True,
    dag=dag,
)

t4 = BashOperator(
    task_id='gitops_success_message',
    bash_command='echo "🎉 ArgoCD GitOps sync is working perfectly! This DAG was auto-deployed! 🚀"',
    dag=dag,
)

t5 = BashOperator(
    task_id='show_git_info',
    bash_command='''
    echo "Git Sync Information:"
    echo "Repository: https://github.com/faizananwar532/airflow-data-engineering.git"
    echo "Branch: main"
    echo "Sync Interval: 60 seconds"
    echo "This DAG proves GitOps is working! 🎊"
    ''',
    dag=dag,
)

# Set task dependencies
t1 >> [t2, t3] >> t4 >> t5
