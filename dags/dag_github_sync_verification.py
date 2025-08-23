"""
GitHub Sync Verification DAG
Created to test automatic GitHub to Airflow synchronization
This DAG should appear in Airflow within 60 seconds of being pushed to GitHub
"""

from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator

# Default arguments
default_args = {
    'owner': 'github-sync-test',
    'depends_on_past': False,
    'start_date': datetime(2024, 8, 24),
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=2),
}

# Define the DAG
dag = DAG(
    'github_sync_verification',
    default_args=default_args,
    description='🚀 Test DAG to verify GitHub sync is working',
    schedule_interval=None,  # Manual trigger only
    catchup=False,
    tags=['github-sync', 'test', 'verification', '🚀'],
)

def print_sync_verification(**kwargs):
    """Print verification information"""
    import os
    from datetime import datetime
    
    print("=" * 60)
    print("🎉 GITHUB SYNC VERIFICATION SUCCESS! 🎉")
    print("=" * 60)
    print(f"✅ This DAG was created at: {datetime.now()}")
    print(f"✅ DAG ID: {kwargs['dag'].dag_id}")
    print(f"✅ Execution Date: {kwargs['execution_date']}")
    print(f"✅ Run ID: {kwargs['dag_run'].run_id}")
    print("")
    print("📋 Environment Information:")
    print(f"   • Hostname: {os.environ.get('HOSTNAME', 'Unknown')}")
    print(f"   • DAGs Folder: {os.environ.get('AIRFLOW__CORE__DAGS_FOLDER', 'Not set')}")
    print(f"   • Git Repo: {os.environ.get('GIT_REPO_URL', 'Not set')}")
    print(f"   • Git Branch: {os.environ.get('GIT_BRANCH', 'Not set')}")
    print("")
    print("🔄 Sync Process:")
    print("   1. DAG created locally")
    print("   2. Committed to Git")
    print("   3. Pushed to GitHub")
    print("   4. Git sidecar synced from GitHub")
    print("   5. Airflow detected and loaded DAG")
    print("   6. DAG now running! 🚀")
    print("=" * 60)
    
    return "GitHub sync verification completed successfully!"

def check_dag_files(**kwargs):
    """Check what DAG files are available"""
    import os
    import glob
    
    dags_folder = os.environ.get('AIRFLOW__CORE__DAGS_FOLDER', '/opt/airflow/dags')
    
    print(f"📁 Checking DAG files in: {dags_folder}")
    print("-" * 50)
    
    try:
        # List all Python files in dags folder
        dag_files = glob.glob(os.path.join(dags_folder, "*.py"))
        dag_files.sort()
        
        print(f"Found {len(dag_files)} DAG files:")
        for i, dag_file in enumerate(dag_files, 1):
            filename = os.path.basename(dag_file)
            size = os.path.getsize(dag_file)
            mtime = datetime.fromtimestamp(os.path.getmtime(dag_file))
            print(f"   {i:2d}. {filename:<35} ({size:>5} bytes, modified: {mtime})")
            
            # Highlight our verification DAG
            if 'verification' in filename.lower():
                print(f"       ⭐ THIS IS OUR NEW VERIFICATION DAG! ⭐")
        
        print("-" * 50)
        
        # Check if our DAG is the newest
        if dag_files:
            newest_dag = max(dag_files, key=os.path.getmtime)
            newest_name = os.path.basename(newest_dag)
            if 'verification' in newest_name.lower():
                print("🎯 Our verification DAG is the newest file - sync is working!")
            else:
                print(f"ℹ️  Newest DAG file: {newest_name}")
                
    except Exception as e:
        print(f"❌ Error checking DAG files: {e}")
    
    return f"DAG files check completed"

# Task 1: Print verification info
verify_sync = PythonOperator(
    task_id='verify_github_sync',
    python_callable=print_sync_verification,
    provide_context=True,
    dag=dag,
)

# Task 2: Check system time and date
check_system = BashOperator(
    task_id='check_system_info',
    bash_command='''
    echo "🕐 System Information:"
    echo "   Current Time: $(date)"
    echo "   Timezone: $(date +%Z)"
    echo "   Uptime: $(uptime -p)"
    echo ""
    echo "📦 Container Information:"
    echo "   Container ID: $(hostname)"
    echo "   User: $(whoami)"
    echo "   Working Dir: $(pwd)"
    echo ""
    echo "🐍 Python Information:"
    echo "   Python Version: $(python --version)"
    echo "   Airflow Version: $(python -c 'import airflow; print(airflow.__version__)')"
    ''',
    dag=dag,
)

# Task 3: Check DAG files
check_files = PythonOperator(
    task_id='check_dag_files',
    python_callable=check_dag_files,
    provide_context=True,
    dag=dag,
)

# Task 4: Final success message
success_message = BashOperator(
    task_id='github_sync_success',
    bash_command='''
    echo ""
    echo "🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊"
    echo "🎊                                                🎊"
    echo "🎊        GITHUB SYNC IS WORKING PERFECTLY!       🎊"
    echo "🎊                                                🎊"
    echo "🎊   ✅ DAG created locally                        🎊"
    echo "🎊   ✅ Pushed to GitHub                           🎊"
    echo "🎊   ✅ Synced to Airflow automatically            🎊"
    echo "🎊   ✅ Running successfully!                      🎊"
    echo "🎊                                                🎊"
    echo "🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊🎊"
    echo ""
    echo "🚀 Your GitHub to Airflow sync is now fully operational!"
    echo "   You can add new DAGs to the 'dags/' folder and they will"
    echo "   automatically appear in Airflow within 60 seconds."
    echo ""
    ''',
    dag=dag,
)

# Set task dependencies
verify_sync >> check_system >> check_files >> success_message
