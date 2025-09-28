#!/usr/bin/env python3
"""
Test script to create a new DAG and push to repository to test GitOps sync
"""

from datetime import datetime, timedelta
import os
import sys

def create_test_dag():
    """Create a test DAG file with current timestamp"""
    
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    dag_id = f"gitops_test_dag_{timestamp}"
    
    dag_content = f'''"""
GitOps Test DAG - Created at {datetime.now()}
This DAG tests the ArgoCD GitOps sync functionality
"""

from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator
import logging

default_args = {{
    'owner': 'gitops-test',
    'depends_on_past': False,
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}}

dag = DAG(
    '{dag_id}',
    default_args=default_args,
    description='🔄 GitOps test DAG created at {datetime.now()}',
    schedule_interval=None,
    start_date=datetime(2023, 1, 1),
    catchup=False,
    tags=['gitops', 'test', 'argocd', '🔄'],
)

def test_gitops_sync(**kwargs):
    """Test function to verify GitOps sync is working"""
    logging.info("🚀 GitOps sync test successful!")
    logging.info(f"DAG ID: {dag_id}")
    logging.info(f"Created at: {datetime.now()}")
    logging.info("This DAG was automatically synced by ArgoCD! 🎉")
    return "GitOps sync working perfectly!"

def check_environment(**kwargs):
    """Check the environment and log system info"""
    import platform
    import subprocess
    
    logging.info("Environment Information:")
    logging.info(f"Python version: {{platform.python_version()}}")
    logging.info(f"Hostname: {{platform.node()}}")
    logging.info(f"Platform: {{platform.platform()}}")
    
    try:
        airflow_version = subprocess.check_output(['airflow', 'version'], text=True).strip()
        logging.info(f"Airflow version: {{airflow_version}}")
    except Exception as e:
        logging.warning(f"Could not get Airflow version: {{e}}")
    
    return "Environment check complete"

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

t3 = BashOperator(
    task_id='gitops_success_message',
    bash_command='echo "🎉 ArgoCD GitOps sync is working perfectly! This DAG was auto-deployed! 🚀"',
    dag=dag,
)

t1 >> t2 >> t3
'''
    
    # Write to dags directory
    dags_dir = "../dags"
    if not os.path.exists(dags_dir):
        os.makedirs(dags_dir)
    
    dag_file = os.path.join(dags_dir, f"dag_gitops_test_{timestamp}.py")
    
    with open(dag_file, 'w') as f:
        f.write(dag_content)
    
    print(f"✅ Created test DAG: {dag_file}")
    print(f"📝 DAG ID: {dag_id}")
    print(f"🕐 Timestamp: {timestamp}")
    
    return dag_file, dag_id

def show_git_commands(dag_file):
    """Show the git commands to push the new DAG"""
    print("\n🔄 Git Commands to Push New DAG:")
    print("=" * 40)
    print("cd ..")  # Go back to project root
    print(f"git add {dag_file}")
    print(f'git commit -m "🔄 Add GitOps test DAG - {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}"')
    print("git push origin main")
    print("\n⏰ After pushing:")
    print("1. ArgoCD will detect the change within ~3 minutes")
    print("2. Airflow pods will restart with the new DAG")
    print("3. Check ArgoCD UI for sync status")
    print("4. New DAG will appear in Airflow UI")

if __name__ == "__main__":
    print("🔄 Creating GitOps Test DAG...")
    print("=" * 50)
    
    dag_file, dag_id = create_test_dag()
    show_git_commands(dag_file)
    
    print(f"\n🚀 Test DAG '{dag_id}' created successfully!")
    print("Use the git commands above to push and test ArgoCD sync.")
'''
