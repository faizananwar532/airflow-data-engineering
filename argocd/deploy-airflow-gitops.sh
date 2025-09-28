#!/bin/bash

set -e

echo "===== Deploy Airflow via ArgoCD GitOps ====="

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

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed or not in PATH"
    exit 1
fi

# Check if ArgoCD is running
if ! kubectl get pods -n argocd | grep -q "Running"; then
    print_error "ArgoCD is not running. Please install ArgoCD first using ./install-argocd.sh"
    exit 1
fi

print_info "ArgoCD is running and ready"

# Check if current Airflow deployment exists
if kubectl get namespace airflow >/dev/null 2>&1; then
    if kubectl get pods -n airflow >/dev/null 2>&1; then
        print_warning "Existing Airflow deployment found"
        echo ""
        print_info "Options:"
        print_info "1. Delete existing deployment and deploy via ArgoCD (recommended)"
        print_info "2. Keep existing deployment (ArgoCD will try to adopt resources)"
        echo ""
        read -p "Choose option (1/2): " choice
        
        if [ "$choice" = "1" ]; then
            print_info "Deleting existing Airflow deployment..."
            # Delete Helm release if it exists
            if helm list -n airflow | grep -q "air"; then
                helm uninstall air -n airflow
                print_status "Helm release deleted"
            fi
            
            # Clean up any remaining resources
            kubectl delete all --all -n airflow --ignore-not-found=true
            kubectl delete configmaps --all -n airflow --ignore-not-found=true
            kubectl delete secrets --all -n airflow --ignore-not-found=true
            kubectl delete pvc --all -n airflow --ignore-not-found=true
            
            print_status "Existing Airflow resources cleaned up"
        fi
    fi
fi

# Create necessary secrets for ArgoCD-managed deployment
print_info "Creating/updating MySQL connection secrets..."

# Ensure airflow namespace exists (ArgoCD will manage it, but secrets need to be created first)
kubectl create namespace airflow --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic airflow-mysql-metadata \
    --namespace airflow \
    --from-literal=connection="mysql://myuser:mypassword@54.167.107.216:3306/mydb" \
    --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic airflow-mysql-result-backend \
    --namespace airflow \
    --from-literal=connection="db+mysql://myuser:mypassword@54.167.107.216:3306/mydb" \
    --dry-run=client -o yaml | kubectl apply -f -

print_status "MySQL connection secrets created/updated"

# Apply the advanced test DAG ConfigMap (if it exists)
if [ -f "../airflow-1.15/airflow-advanced-test-dag-configmap.yaml" ]; then
    print_info "Applying advanced test DAG ConfigMap..."
    kubectl apply -f ../airflow-1.15/airflow-advanced-test-dag-configmap.yaml -n airflow
    print_status "Advanced test DAG ConfigMap applied"
fi

# Deploy Airflow Application via ArgoCD
print_info "Deploying Airflow Application via ArgoCD..."

# Check if we have a file with sensitive values
if [ -f "airflow-application-with-secrets.yaml" ]; then
    print_info "Using configuration with sensitive values..."
    kubectl apply -f airflow-application-with-secrets.yaml
    print_warning "Consider deleting airflow-application-with-secrets.yaml after deployment"
else
    print_warning "Using default airflow-application.yaml (may contain placeholder values)"
    print_info "Run ./configure-sensitive-values.sh to create a secure configuration"
    kubectl apply -f airflow-application.yaml
fi

print_status "ArgoCD Application created"

# Wait for ArgoCD to sync the application
print_info "Waiting for ArgoCD to sync the application..."
echo "This may take a few minutes..."

# Monitor the application sync status
for i in {1..30}; do
    SYNC_STATUS=$(kubectl get application airflow-gitops -n argocd -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "Unknown")
    HEALTH_STATUS=$(kubectl get application airflow-gitops -n argocd -o jsonpath='{.status.health.status}' 2>/dev/null || echo "Unknown")
    
    print_info "Sync Status: $SYNC_STATUS | Health Status: $HEALTH_STATUS"
    
    if [ "$SYNC_STATUS" = "Synced" ] && [ "$HEALTH_STATUS" = "Healthy" ]; then
        print_status "Application synced and healthy!"
        break
    fi
    
    if [ "$SYNC_STATUS" = "OutOfSync" ] || [ "$HEALTH_STATUS" = "Degraded" ]; then
        print_warning "Application sync issues detected. Check ArgoCD UI for details."
    fi
    
    sleep 10
done

# Check final status
FINAL_SYNC=$(kubectl get application airflow-gitops -n argocd -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "Unknown")
FINAL_HEALTH=$(kubectl get application airflow-gitops -n argocd -o jsonpath='{.status.health.status}' 2>/dev/null || echo "Unknown")

echo ""
print_info "Final Application Status:"
print_info "Sync Status: $FINAL_SYNC"
print_info "Health Status: $FINAL_HEALTH"

# Show Airflow pods status
echo ""
print_info "Airflow Pods Status:"
kubectl get pods -n airflow

# Get Airflow LoadBalancer URL
echo ""
print_info "Getting Airflow LoadBalancer URL..."
AIRFLOW_URL=$(kubectl get svc air-webserver -n airflow -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
if [ -z "$AIRFLOW_URL" ]; then
    AIRFLOW_URL=$(kubectl get svc air-webserver -n airflow -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
fi

# Get ArgoCD URL
ARGOCD_URL=$(kubectl get svc argocd-server-loadbalancer -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
if [ -z "$ARGOCD_URL" ]; then
    ARGOCD_URL=$(kubectl get svc argocd-server-loadbalancer -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
fi

echo ""
print_status "GitOps Airflow Deployment Completed! 🚀"
echo ""
print_info "Access Information:"
print_info "=================="
if [ -n "$AIRFLOW_URL" ]; then
    print_info "🌐 Airflow UI: http://$AIRFLOW_URL:8080"
else
    print_info "🌐 Airflow UI: Check LoadBalancer with 'kubectl get svc air-webserver -n airflow'"
fi

if [ -n "$ARGOCD_URL" ]; then
    print_info "🔄 ArgoCD UI: http://$ARGOCD_URL"
else
    print_info "🔄 ArgoCD UI: Check LoadBalancer with 'kubectl get svc argocd-server-loadbalancer -n argocd'"
fi

echo ""
print_info "GitOps Workflow:"
print_info "================"
print_info "1. 📝 Add/modify DAGs in your GitHub repository (dags/ folder)"
print_info "2. 🔄 ArgoCD automatically detects changes and syncs"
print_info "3. 🚀 Airflow pods restart with new DAGs"
print_info "4. ✅ New DAGs appear in Airflow UI automatically"

echo ""
print_info "Monitoring Commands:"
print_info "==================="
print_info "• ArgoCD App Status: kubectl get application airflow-gitops -n argocd"
print_info "• Airflow Pods: kubectl get pods -n airflow"
print_info "• ArgoCD Sync: kubectl describe application airflow-gitops -n argocd"
print_info "• Force Sync: kubectl patch application airflow-gitops -n argocd -p '{\"operation\":{\"sync\":{}}}' --type merge"

echo ""
print_warning "Important Notes:"
print_info "• ArgoCD monitors your GitHub repository for changes"
print_info "• Auto-sync is enabled - changes deploy automatically"
print_info "• Self-healing is enabled - manual changes are reverted"
print_info "• Check ArgoCD UI for detailed sync status and logs"
print_status "Your Airflow is now fully GitOps managed! 🎉"
