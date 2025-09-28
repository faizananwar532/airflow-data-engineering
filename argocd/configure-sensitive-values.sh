#!/bin/bash

set -e

echo "===== Configure Sensitive Values for ArgoCD GitOps ====="

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

# Default values (you MUST override these with your actual credentials)
MYSQL_CONNECTION="${MYSQL_CONNECTION:-mysql://YOUR_USER:YOUR_PASSWORD@YOUR_HOST:3306/YOUR_DB}"
AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-YOUR_AWS_ACCESS_KEY_ID}"
AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-YOUR_AWS_SECRET_ACCESS_KEY}"
S3_LOG_BUCKET="${S3_LOG_BUCKET:-s3://your-s3-bucket/logs}"
FERNET_KEY="${FERNET_KEY:-YOUR_FERNET_KEY_HERE}"

# Validate that we don't have placeholder values
if [[ "$MYSQL_CONNECTION" == *"YOUR_"* ]] || [[ "$AWS_ACCESS_KEY_ID" == *"YOUR_"* ]] || [[ "$FERNET_KEY" == *"YOUR_"* ]]; then
    print_error "Placeholder values detected! You must provide actual credentials."
    print_info "Set environment variables before running this script:"
    print_info "export MYSQL_CONNECTION=\"mysql://user:pass@host:port/db\""
    print_info "export AWS_ACCESS_KEY_ID=\"your-access-key\""
    print_info "export AWS_SECRET_ACCESS_KEY=\"your-secret-key\""
    print_info "export S3_LOG_BUCKET=\"s3://your-bucket/logs\""
    print_info "export FERNET_KEY=\"your-fernet-key\""
    echo ""
    print_warning "Or run this script and enter values interactively when prompted."
fi

print_info "Current Configuration:"
print_info "MySQL Connection: ${MYSQL_CONNECTION}"
print_info "AWS Access Key: ${AWS_ACCESS_KEY_ID}"
print_info "AWS Secret Key: [HIDDEN]"
print_info "S3 Log Bucket: ${S3_LOG_BUCKET}"
print_info "Fernet Key: [HIDDEN]"
echo ""

read -p "Do you want to update these values? (y/N): " update_values

if [ "$update_values" = "y" ] || [ "$update_values" = "Y" ]; then
    echo ""
    print_info "Enter new values (press Enter to keep current):"
    
    read -p "MySQL Connection: " new_mysql
    if [ -n "$new_mysql" ]; then
        MYSQL_CONNECTION="$new_mysql"
    fi
    
    read -p "AWS Access Key ID: " new_aws_key
    if [ -n "$new_aws_key" ]; then
        AWS_ACCESS_KEY_ID="$new_aws_key"
    fi
    
    read -p "AWS Secret Access Key: " new_aws_secret
    if [ -n "$new_aws_secret" ]; then
        AWS_SECRET_ACCESS_KEY="$new_aws_secret"
    fi
    
    read -p "S3 Log Bucket: " new_s3_bucket
    if [ -n "$new_s3_bucket" ]; then
        S3_LOG_BUCKET="$new_s3_bucket"
    fi
    
    read -p "Fernet Key: " new_fernet
    if [ -n "$new_fernet" ]; then
        FERNET_KEY="$new_fernet"
    fi
fi

print_info "Updating ArgoCD Application with sensitive values..."

# Create a temporary application file with sensitive values
cat > airflow-application-with-secrets.yaml << EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: airflow-gitops
  namespace: argocd
  labels:
    app.kubernetes.io/name: airflow
    app.kubernetes.io/component: application
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/faizananwar532/airflow-data-engineering.git
    targetRevision: HEAD
    path: airflow-1.15
    helm:
      valueFiles:
        - mysql-github-values-public.yaml
      parameters:
        # Deployment sizing
        - name: scheduler.replicas
          value: "1"
        - name: webserver.replicas
          value: "1"
        - name: workers.replicas
          value: "1"
        
        # Sensitive MySQL connections
        - name: env[0].value
          value: "${MYSQL_CONNECTION}"
        - name: env[1].value
          value: "${MYSQL_CONNECTION}"
        
        # AWS credentials
        - name: env[3].value
          value: "${AWS_ACCESS_KEY_ID}"
        - name: env[4].value
          value: "${AWS_SECRET_ACCESS_KEY}"
        
        # S3 log bucket
        - name: env[7].value
          value: "${S3_LOG_BUCKET}"
        - name: config.logging.remote_base_log_folder
          value: "${S3_LOG_BUCKET}"
        
        # Fernet key
        - name: env[9].value
          value: "${FERNET_KEY}"
        - name: config.core.fernet_key
          value: "${FERNET_KEY}"
  destination:
    server: https://kubernetes.default.svc
    namespace: airflow
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
      allowEmpty: false
    syncOptions:
      - CreateNamespace=true
      - PrunePropagationPolicy=foreground
      - PruneLast=true
      - ApplyOutOfSyncOnly=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
  revisionHistoryLimit: 10
  info:
    - name: Description
      value: "GitOps managed Airflow deployment with automatic DAG synchronization"
    - name: Repository
      value: "https://github.com/faizananwar532/airflow-data-engineering"
    - name: Sync Method
      value: "GitHub Direct Sync with ArgoCD GitOps"
EOF

print_status "Configuration file created with sensitive values"
print_warning "The file 'airflow-application-with-secrets.yaml' contains sensitive data"
print_warning "Do NOT commit this file to Git!"
print_info "✅ This file is protected by .gitignore"

echo ""
print_info "Next steps:"
print_info "1. Review the generated file: airflow-application-with-secrets.yaml"
print_info "2. Apply it using: kubectl apply -f airflow-application-with-secrets.yaml"
print_info "3. Delete the file after applying: rm airflow-application-with-secrets.yaml"
print_info "4. Commit the public values file: mysql-github-values-public.yaml"

echo ""
print_status "Configuration script completed!"
print_warning "Remember: Keep sensitive values secure and never commit them to Git!"
