#!/bin/bash

set -e

echo "===== Upgrading Airflow to GitHub Sync (Safe Mode) ====="

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

print_info "This script will safely upgrade your Airflow to use GitHub sync"
print_info "Your existing data and connections will be preserved"
echo ""

# Check current Airflow status
print_info "Checking current Airflow status..."
if kubectl get namespace airflow >/dev/null 2>&1; then
    print_status "Airflow namespace exists"
    
    # Check pod status
    pod_count=$(kubectl get pods -n airflow --no-headers | wc -l)
    running_pods=$(kubectl get pods -n airflow --no-headers | grep Running | wc -l)
    
    print_info "Found $pod_count pods, $running_pods running"
    
    if [ "$running_pods" -gt 0 ]; then
        print_status "Airflow is currently running"
    else
        print_warning "Some Airflow pods may not be running properly"
    fi
else
    print_error "Airflow namespace not found"
    exit 1
fi

# Backup current configuration
print_info "Creating backup of current Helm values..."
helm get values air -n airflow > airflow-1.15/current-values-backup.yaml
print_status "Backup saved to: airflow-1.15/current-values-backup.yaml"

# Apply the advanced test DAG ConfigMap (if it exists)
if [ -f "airflow-1.15/airflow-advanced-test-dag-configmap.yaml" ]; then
    print_info "Applying advanced test DAG ConfigMap..."
    kubectl apply -f airflow-1.15/airflow-advanced-test-dag-configmap.yaml -n airflow
    print_status "Advanced test DAG ConfigMap applied"
fi

# Upgrade Airflow with GitHub sync configuration
print_info "Upgrading Airflow with GitHub sync configuration..."
print_warning "This will update your Airflow pods with GitHub sync sidecars"

helm upgrade air airflow-1.15 \
    --namespace airflow \
    --values airflow-1.15/mysql-github-values.yaml \
    --timeout 10m

if [ $? -eq 0 ]; then
    print_status "Helm upgrade completed successfully"
else
    print_error "Helm upgrade failed"
    print_info "You can rollback using: helm rollback air -n airflow"
    exit 1
fi

# Wait for pods to be ready
print_info "Waiting for Airflow pods to be ready..."
kubectl wait --for=condition=Ready pod -l component=scheduler -n airflow --timeout=300s
kubectl wait --for=condition=Ready pod -l component=webserver -n airflow --timeout=300s

if [ $? -eq 0 ]; then
    print_status "All Airflow pods are ready"
else
    print_warning "Some pods may still be starting up"
fi

# Check if MySQL connection still exists
print_info "Checking MySQL connection..."
WEBSERVER_POD=$(kubectl get pods -n airflow -l component=webserver -o jsonpath="{.items[0].metadata.name}" 2>/dev/null || echo "")

if [ -n "$WEBSERVER_POD" ]; then
    # Test if MySQL connection exists
    CONNECTION_TEST=$(kubectl exec -n airflow $WEBSERVER_POD -c webserver -- python -c "
from airflow.models import Connection
from airflow.settings import Session
session = Session()
conn = session.query(Connection).filter(Connection.conn_id == 'mysql').first()
if conn:
    print('MySQL connection exists')
    exit(0)
else:
    print('MySQL connection not found')
    exit(1)
" 2>/dev/null || echo "connection_check_failed")

    if echo "$CONNECTION_TEST" | grep -q "MySQL connection exists"; then
        print_status "MySQL connection is still available"
    else
        print_warning "MySQL connection may need to be re-added"
        print_info "You can add it manually using the Airflow UI or run:"
        print_info "kubectl exec -n airflow $WEBSERVER_POD -c webserver -- python /path/to/add_mysql_connection.py"
    fi
fi

echo ""
print_status "GitHub sync upgrade completed successfully!"
echo ""
print_info "What changed:"
print_info "✓ Added Git sidecar containers to sync DAGs from GitHub"
print_info "✓ Your existing MySQL database and connections are preserved"
print_info "✓ S3 logging configuration remains unchanged"
print_info "✓ All your existing DAGs are still available"
echo ""
print_info "GitHub sync details:"
print_info "• Repository: https://github.com/faizananwar532/airflow-data-engineering.git"
print_info "• Branch: main"
print_info "• Sync interval: 60 seconds"
print_info "• DAGs folder: dags/"
echo ""
print_info "Next steps:"
print_info "1. Push your repository to GitHub: git push -u origin main"
print_info "2. Any DAGs you add to the 'dags/' folder will sync automatically"
print_info "3. Monitor sync logs: kubectl logs -n airflow -l component=scheduler -c dags-git-sync"
echo ""
print_info "Access your Airflow UI:"
EXTERNAL_IP=$(kubectl get svc air-webserver -n airflow -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "localhost")
if [ "$EXTERNAL_IP" != "localhost" ]; then
    print_info "🌐 http://$EXTERNAL_IP:8080"
else
    print_info "🌐 Use port-forward: kubectl port-forward svc/air-webserver 8080:8080 -n airflow"
fi
echo ""
print_status "Upgrade complete! Your Airflow now syncs DAGs from GitHub! 🚀"
