#!/bin/bash

set -e

echo "===== Deploy Airflow with GitHub Sync ====="
echo "Usage: Run this script from the project root directory"
echo "Example: ./scripts/deploy-with-github-sync.sh"
echo ""

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

# AWS credentials - set these before running the script
AWS_ACCESS_KEY="${AWS_ACCESS_KEY_ID:-}"
AWS_SECRET_KEY="${AWS_SECRET_ACCESS_KEY:-}"

if [ -z "$AWS_ACCESS_KEY" ] || [ -z "$AWS_SECRET_KEY" ]; then
    print_error "Please set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY environment variables"
    print_info "Example: export AWS_ACCESS_KEY_ID=your_key_here"
    print_info "         export AWS_SECRET_ACCESS_KEY=your_secret_here"
    exit 1
fi

# Check if we're in the right directory
if [ ! -f "airflow-1.15/mysql-github-values.yaml" ]; then
    print_error "Please run this script from the project root directory"
    exit 1
fi

# We're already in the right directory, no need to cd

print_info "This script will deploy Airflow with GitHub sync using your AWS credentials"
print_warning "AWS credentials will be set via environment variables, not stored in files"
echo ""

# Create a temporary values file with real credentials
print_info "Creating temporary values file with AWS credentials..."
cp airflow-1.15/mysql-github-values.yaml airflow-1.15/mysql-github-values-temp.yaml

# Replace placeholder credentials with real ones
sed -i "s/YOUR_AWS_ACCESS_KEY_ID/$AWS_ACCESS_KEY/g" airflow-1.15/mysql-github-values-temp.yaml
sed -i "s/YOUR_AWS_SECRET_ACCESS_KEY/$AWS_SECRET_KEY/g" airflow-1.15/mysql-github-values-temp.yaml

print_status "Temporary values file created with real AWS credentials"

# Check current Airflow status
print_info "Checking current Airflow status..."
if kubectl get namespace airflow >/dev/null 2>&1; then
    print_status "Airflow namespace exists"
    
    # Check if this is an upgrade or new installation
    if helm list -n airflow | grep -q "air"; then
        print_info "Existing Airflow installation found - will upgrade"
        DEPLOYMENT_TYPE="upgrade"
    else
        print_info "No existing Airflow installation - will install"
        DEPLOYMENT_TYPE="install"
    fi
else
    print_info "Creating Airflow namespace..."
    kubectl create namespace airflow
    DEPLOYMENT_TYPE="install"
fi

# Apply the advanced test DAG ConfigMap (if it exists)
if [ -f "airflow-1.15/airflow-advanced-test-dag-configmap.yaml" ]; then
    print_info "Applying advanced test DAG ConfigMap..."
    kubectl apply -f airflow-1.15/airflow-advanced-test-dag-configmap.yaml -n airflow
    print_status "Advanced test DAG ConfigMap applied"
fi

# Create MySQL connection secrets if they don't exist
print_info "Creating/updating MySQL connection secrets..."
kubectl create secret generic airflow-mysql-metadata \
    --namespace airflow \
    --from-literal=connection="mysql://myuser:mypassword@54.167.107.216:3306/mydb" \
    --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic airflow-mysql-result-backend \
    --namespace airflow \
    --from-literal=connection="db+mysql://myuser:mypassword@54.167.107.216:3306/mydb" \
    --dry-run=client -o yaml | kubectl apply -f -

print_status "MySQL connection secrets created/updated"

# Deploy/Upgrade Airflow
if [ "$DEPLOYMENT_TYPE" = "upgrade" ]; then
    print_info "Upgrading Airflow with GitHub sync configuration..."
    helm upgrade air airflow-1.15 \
        --namespace airflow \
        --values airflow-1.15/mysql-github-values-temp.yaml \
        --timeout 10m
else
    print_info "Installing Airflow with GitHub sync configuration..."
    helm install air airflow-1.15 \
        --namespace airflow \
        --values airflow-1.15/mysql-github-values-temp.yaml \
        --timeout 10m
fi

if [ $? -eq 0 ]; then
    print_status "Helm $DEPLOYMENT_TYPE completed successfully"
else
    print_error "Helm $DEPLOYMENT_TYPE failed"
    if [ "$DEPLOYMENT_TYPE" = "upgrade" ]; then
        print_info "You can rollback using: helm rollback air -n airflow"
    fi
    # Clean up temp file
    rm -f airflow-1.15/mysql-github-values-temp.yaml
    exit 1
fi

# Clean up temporary file with credentials
rm -f airflow-1.15/mysql-github-values-temp.yaml
print_status "Temporary credentials file cleaned up"

# Wait for pods to be ready
print_info "Waiting for Airflow pods to be ready..."
kubectl wait --for=condition=Ready pod -l component=scheduler -n airflow --timeout=300s
kubectl wait --for=condition=Ready pod -l component=webserver -n airflow --timeout=300s

if [ $? -eq 0 ]; then
    print_status "All Airflow pods are ready"
else
    print_warning "Some pods may still be starting up"
fi

# Add MySQL connection if it's a new installation
if [ "$DEPLOYMENT_TYPE" = "install" ]; then
    print_info "Adding MySQL connection to Airflow..."
    WEBSERVER_POD=$(kubectl get pods -n airflow -l component=webserver -o jsonpath="{.items[0].metadata.name}" 2>/dev/null || echo "")
    
    if [ -n "$WEBSERVER_POD" ]; then
        # Copy and execute the connection script
        kubectl cp scripts/add_mysql_connection.py "airflow/$WEBSERVER_POD:/tmp/add_mysql_connection.py" -c webserver
        kubectl exec -n airflow $WEBSERVER_POD -c webserver -- chmod +x /tmp/add_mysql_connection.py
        kubectl exec -n airflow $WEBSERVER_POD -c webserver -- python /tmp/add_mysql_connection.py
        print_status "MySQL connection added"
    fi
fi

echo ""
print_status "GitHub sync deployment completed successfully!"
echo ""
print_info "GitHub sync details:"
print_info "• Repository: https://github.com/faizananwar532/airflow-data-engineering.git"
print_info "• Branch: main"
print_info "• Sync interval: 60 seconds"
print_info "• DAGs folder: dags/"
echo ""
print_info "Monitor GitHub sync:"
print_info "kubectl logs -n airflow -l component=scheduler -c dags-git-sync --follow"
echo ""
print_info "Access your Airflow UI:"
EXTERNAL_IP=$(kubectl get svc air-webserver -n airflow -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "localhost")
if [ "$EXTERNAL_IP" != "localhost" ]; then
    print_info "🌐 http://$EXTERNAL_IP:8080"
else
    print_info "🌐 Use port-forward: kubectl port-forward svc/air-webserver 8080:8080 -n airflow"
fi
echo ""
print_status "Your Airflow now syncs DAGs from GitHub every 60 seconds! 🚀"
