#!/bin/bash

set -e

echo "===== Direct GitHub to Airflow Sync Setup ====="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if we're in the right directory
if [ ! -f "../airflow-1.15/mysql-github-values.yaml" ]; then
    print_error "Please run this script from the scripts directory"
    exit 1
fi

cd ..

# Function to get user input
get_github_info() {
    echo ""
    print_info "We need your GitHub repository information:"
    
    # Get GitHub username
    read -p "Enter your GitHub username: " github_username
    if [ -z "$github_username" ]; then
        print_error "GitHub username is required"
        exit 1
    fi
    
    # Get repository name
    read -p "Enter your repository name (default: airflow-dags): " repo_name
    if [ -z "$repo_name" ]; then
        repo_name="airflow-dags"
    fi
    
    # Get branch name
    read -p "Enter branch name (default: main): " branch_name
    if [ -z "$branch_name" ]; then
        branch_name="main"
    fi
    
    # Get sync interval
    read -p "Enter sync interval in seconds (default: 60): " sync_interval
    if [ -z "$sync_interval" ]; then
        sync_interval="60"
    fi
    
    github_repo_url="https://github.com/$github_username/$repo_name.git"
    
    print_status "Configuration:"
    print_info "GitHub URL: $github_repo_url"
    print_info "Branch: $branch_name"
    print_info "Sync Interval: ${sync_interval}s"
    
    echo ""
    read -p "Is this correct? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Please run the script again with correct information"
        exit 0
    fi
}

# Update the Helm values file
update_helm_values() {
    print_info "Updating Helm values file with your GitHub repository..."
    
    values_file="airflow-1.15/mysql-github-values.yaml"
    
    # Update the repository URL, branch, and sync interval in the values file
    sed -i "s|https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git|$github_repo_url|g" "$values_file"
    sed -i "s|value: \"main\"|value: \"$branch_name\"|g" "$values_file"
    sed -i "s|value: \"60\"  # seconds|value: \"$sync_interval\"  # seconds|g" "$values_file"
    
    print_status "Helm values file updated successfully"
}

# Initialize git repository if needed
setup_git_repo() {
    print_info "Setting up Git repository..."
    
    if [ ! -d ".git" ]; then
        git init
        print_status "Git repository initialized"
    else
        print_status "Git repository already exists"
    fi
    
    # Create .gitignore if it doesn't exist
    if [ ! -f ".gitignore" ]; then
        cat > .gitignore << 'EOF'
# Python
__pycache__/
*.py[cod]
*$py.class
*.pyc

# Virtual environments
venv/
env/

# IDE
.vscode/
.idea/
*.swp

# OS
.DS_Store
Thumbs.db

# Secrets
*.pem
*.key
secrets/

# Airflow
airflow.db
airflow.cfg

# Kubernetes
*.kubeconfig
EOF
        print_status ".gitignore created"
    fi
    
    # Add and commit files
    git add .
    if ! git diff --staged --quiet; then
        git commit -m "Setup direct GitHub sync for Airflow DAGs

- Added mysql-github-values.yaml for direct GitHub sync
- Configured Git sidecar containers for scheduler, webserver, and workers
- Repository: $github_repo_url
- Branch: $branch_name
- Sync interval: ${sync_interval}s"
        print_status "Changes committed to Git"
    else
        print_info "No changes to commit"
    fi
    
    # Add remote if it doesn't exist
    if ! git remote get-url origin >/dev/null 2>&1; then
        git remote add origin "$github_repo_url"
        print_status "GitHub remote added"
    else
        current_remote=$(git remote get-url origin)
        if [ "$current_remote" != "$github_repo_url" ]; then
            git remote set-url origin "$github_repo_url"
            print_status "GitHub remote updated"
        else
            print_status "GitHub remote already configured"
        fi
    fi
}

# Create sample DAG for testing
create_sample_dag() {
    print_info "Creating sample DAG for testing..."
    
    mkdir -p dags
    
    cat > dags/dag_github_direct_sync_test.py << 'EOF'
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
EOF

    print_status "Sample DAG created: dags/dag_github_direct_sync_test.py"
}

# Deploy with new configuration
deploy_airflow() {
    echo ""
    print_info "Ready to deploy Airflow with direct GitHub sync!"
    print_warning "This will redeploy your Airflow installation."
    
    read -p "Do you want to deploy now? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Deploying Airflow with GitHub sync..."
        
        # Use the reset script but with the new values file
        if [ -f "scripts/reset-airflow.sh" ]; then
            # Create a modified reset script for GitHub sync
            cp scripts/reset-airflow.sh scripts/reset-airflow-github.sh
            
            # Update the Helm install command to use the new values file
            sed -i 's|mysql-values.yaml|mysql-github-values.yaml|g' scripts/reset-airflow-github.sh
            
            chmod +x scripts/reset-airflow-github.sh
            
            print_info "Running deployment script..."
            ./scripts/reset-airflow-github.sh
        else
            print_error "Reset script not found. Please deploy manually:"
            print_info "helm upgrade air airflow-1.15 --namespace airflow --values airflow-1.15/mysql-github-values.yaml"
        fi
    else
        print_info "Deployment skipped. You can deploy later using:"
        print_info "helm upgrade air airflow-1.15 --namespace airflow --values airflow-1.15/mysql-github-values.yaml"
    fi
}

# Main execution
echo ""
print_info "This script will set up direct GitHub to Airflow DAG synchronization."
print_info "Your DAGs will be synced directly from your GitHub repository every 60 seconds."
echo ""

# Get GitHub repository information
get_github_info

# Update Helm values
update_helm_values

# Setup Git repository
setup_git_repo

# Create sample DAG
create_sample_dag

echo ""
print_status "Direct GitHub sync setup completed!"
echo ""
print_info "What happens next:"
print_info "1. Push your repository to GitHub: git push -u origin $branch_name"
print_info "2. Deploy Airflow with the new configuration"
print_info "3. Your DAGs will automatically sync from GitHub every ${sync_interval} seconds"
print_info "4. No need for GitHub Actions or S3 - direct Git sync!"
echo ""
print_warning "Important notes:"
print_warning "- Make sure your GitHub repository is public, or configure Git credentials for private repos"
print_warning "- The sync happens every ${sync_interval} seconds automatically"
print_warning "- DAGs are synced from the 'dags/' directory in your repository"
echo ""

# Offer to deploy
deploy_airflow

print_status "Setup complete! 🚀"
echo ""
print_info "To test the sync:"
print_info "1. Push this repository to GitHub"
print_info "2. Make changes to DAGs in the 'dags/' directory"
print_info "3. Push changes to GitHub"
print_info "4. Wait up to ${sync_interval} seconds"
print_info "5. Check Airflow UI for updated DAGs"
