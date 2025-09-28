#!/bin/bash

set -e

echo "===== Installing ArgoCD with LoadBalancer ====="

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

# Check if we can connect to the cluster
if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to Kubernetes cluster. Please check your kubeconfig"
    exit 1
fi

print_info "Connected to Kubernetes cluster"

# Create ArgoCD namespace
print_info "Creating ArgoCD namespace..."
kubectl apply -f namespace.yaml
print_status "ArgoCD namespace created"

# Install ArgoCD
print_info "Installing ArgoCD core components..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

print_status "ArgoCD core components installed"

# Wait for ArgoCD components to be ready
print_info "Waiting for ArgoCD pods to be ready..."
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=argocd-repo-server -n argocd --timeout=300s
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=argocd-application-controller -n argocd --timeout=300s

print_status "ArgoCD pods are ready"

# Apply LoadBalancer service
print_info "Creating LoadBalancer service for ArgoCD..."
kubectl apply -f argocd-server-loadbalancer.yaml
print_status "LoadBalancer service created"

# Wait for LoadBalancer to get external IP
print_info "Waiting for LoadBalancer to get external IP..."
echo "This may take a few minutes..."

# Wait up to 5 minutes for external IP
for i in {1..30}; do
    EXTERNAL_IP=$(kubectl get svc argocd-server-loadbalancer -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
    if [ -z "$EXTERNAL_IP" ]; then
        EXTERNAL_IP=$(kubectl get svc argocd-server-loadbalancer -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    fi
    
    if [ -n "$EXTERNAL_IP" ]; then
        break
    fi
    
    echo "Waiting for external IP... (attempt $i/30)"
    sleep 10
done

if [ -n "$EXTERNAL_IP" ]; then
    print_status "LoadBalancer external IP/hostname: $EXTERNAL_IP"
else
    print_warning "LoadBalancer is still pending external IP. You can check status with:"
    print_info "kubectl get svc argocd-server-loadbalancer -n argocd"
fi

# Get ArgoCD admin password
print_info "Retrieving ArgoCD admin password..."
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo ""
print_status "ArgoCD installation completed successfully! 🚀"
echo ""
print_info "Access Information:"
print_info "==================="
if [ -n "$EXTERNAL_IP" ]; then
    print_info "🌐 ArgoCD UI: http://$EXTERNAL_IP"
    print_info "🌐 ArgoCD UI (HTTPS): https://$EXTERNAL_IP"
else
    print_info "🌐 ArgoCD UI: Check LoadBalancer IP with 'kubectl get svc argocd-server-loadbalancer -n argocd'"
fi
print_info "👤 Username: admin"
print_info "🔑 Password: $ARGOCD_PASSWORD"
echo ""
print_info "Useful Commands:"
print_info "================"
print_info "• Check ArgoCD status: kubectl get pods -n argocd"
print_info "• Check LoadBalancer: kubectl get svc argocd-server-loadbalancer -n argocd"
print_info "• Port forward (alternative): kubectl port-forward svc/argocd-server-loadbalancer 8080:80 -n argocd"
print_info "• Get admin password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
echo ""
print_warning "Note: Save the admin password securely. The initial admin secret will be deleted after first login."
print_info "You can change the password later through the ArgoCD UI or CLI."
