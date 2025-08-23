"""
Direct GitHub Sync Test DAG
This DAG is synced directly from GitHub to Airflow using Git sidecar containers.
"""

from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator

default_args = {
    'owner': 'github-direct',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

dag = DAG(
    'github_direct_sync_test',
    default_args=default_args,
    description='Test DAG for direct GitHub to Airflow sync',
    schedule_interval=None,
    catchup=False,
    tags=['github', 'direct-sync', 'test'],
)

def print_sync_info(**kwargs):
    """Print information about direct GitHub sync"""
    import os
    from datetime import datetime
    
    print("=== Direct GitHub Sync Test ===")
    print(f"Execution time: {datetime.now()}")
    print(f"DAG run ID: {kwargs['dag_run'].run_id}")
    print("✅ This DAG was synced directly from GitHub!")
    
    # Print environment info
    print("\n=== Environment Info ===")
    print(f"DAGs folder: {os.environ.get('AIRFLOW__CORE__DAGS_FOLDER', 'Not set')}")
    print(f"Git repo URL: {os.environ.get('GIT_REPO_URL', 'Not set')}")
    print(f"Git branch: {os.environ.get('GIT_BRANCH', 'Not set')}")
    print(f"Sync interval: {os.environ.get('GIT_SYNC_INTERVAL', 'Not set')}s")
    
    return "Direct GitHub sync test completed!"

# Task 1: Print sync information
t1 = PythonOperator(
    task_id='print_sync_info',
    python_callable=print_sync_info,
    provide_context=True,
    dag=dag,
)

# Task 2: Check DAGs directory
t2 = BashOperator(
    task_id='check_dags_directory',
    bash_command='''
    echo "=== DAGs Directory Contents ==="
    ls -la /opt/airflow/dags/
    echo ""
    echo "=== Python DAG Files ==="
    find /opt/airflow/dags -name "*.py" -type f | head -10
    echo ""
    echo "=== Git Sync Container Status ==="
    ps aux | grep git || echo "Git processes not visible from this container"
    ''',
    dag=dag,
)

# Task 3: Success message
t3 = BashOperator(
    task_id='success_message',
    bash_command='echo "🎉 Direct GitHub sync is working perfectly! Your DAGs are automatically synced from GitHub."',
    dag=dag,
)

# Set task dependencies
t1 >> t2 >> t3
