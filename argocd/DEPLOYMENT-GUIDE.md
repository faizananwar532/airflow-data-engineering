# 🚀 Complete Deployment Guide

This guide walks you through deploying Airflow with ArgoCD GitOps from start to finish.

## 📋 Prerequisites

- ✅ Kubernetes cluster (EKS) running
- ✅ `kubectl` configured and connected
- ✅ MySQL database running on EC2 (54.167.107.216:3306)
- ✅ AWS S3 bucket for logs
- ✅ Your actual credentials ready

## 🔐 Step 1: Prepare Your Credentials

Before deployment, gather these credentials:

```bash
# MySQL connection
MYSQL_CONNECTION="mysql://myuser:mypassword@54.167.107.216:3306/mydb"

# AWS credentials
AWS_ACCESS_KEY_ID="your-actual-access-key"
AWS_SECRET_ACCESS_KEY="your-actual-secret-key"

# S3 bucket for logs
S3_LOG_BUCKET="s3://your-actual-bucket/logs"

# Fernet key (generate new one or use existing)
FERNET_KEY="your-actual-fernet-key"
```

## 🚀 Step 2: Deploy ArgoCD

```bash
# Navigate to ArgoCD directory
cd airflow-data-engineering/argocd

# Install ArgoCD
./install-argocd.sh

# Wait for completion and note the admin password
# Access ArgoCD UI and login
```

## 📦 Step 3: Commit Safe Files to Git

```bash
# Go to project root
cd ..

# Add safe files (no sensitive data)
git add .gitignore
git add airflow-1.15/mysql-github-values-public.yaml
git add argocd/

# Commit
git commit -m "🔐 Add secure ArgoCD GitOps setup

- Add mysql-github-values-public.yaml (no sensitive data)
- Create ArgoCD Application templates with placeholders
- Add configure-sensitive-values.sh for credential management
- Update .gitignore to protect sensitive files
- Complete secure GitOps workflow setup"

# Push to GitHub
git push origin main
```

## 🔑 Step 4: Configure Sensitive Values

```bash
# Go back to ArgoCD directory
cd argocd

# Option A: Set environment variables first
export MYSQL_CONNECTION="mysql://myuser:mypassword@54.167.107.216:3306/mydb"
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export S3_LOG_BUCKET="s3://airflow-logs-ravi/logs"
export FERNET_KEY="46BKJoQYlPPOexq0OhDZnIlNepKFf87WFwLbfzqDDho="

# Then run the script
./configure-sensitive-values.sh

# Option B: Run script and enter values interactively
./configure-sensitive-values.sh
# (Enter your actual values when prompted)
```

This creates `airflow-application-with-secrets.yaml` with your real credentials.

## 🚀 Step 5: Deploy Airflow via ArgoCD

```bash
# Deploy using GitOps
./deploy-airflow-gitops.sh
```

This script will:
- ✅ Clean up existing Helm deployments
- ✅ Create MySQL connection secrets
- ✅ Apply the ArgoCD Application with your credentials
- ✅ Monitor deployment progress
- ✅ Show access URLs

## 🔍 Step 6: Verify Deployment

### Check ArgoCD Application
```bash
# Application status
kubectl get application airflow-gitops -n argocd

# Detailed status
kubectl describe application airflow-gitops -n argocd
```

### Check Airflow Pods
```bash
# Pod status
kubectl get pods -n airflow

# Watch pods starting
kubectl get pods -n airflow -w
```

### Access UIs
```bash
# Get ArgoCD URL
kubectl get svc argocd-server-loadbalancer -n argocd

# Get Airflow URL  
kubectl get svc air-webserver -n airflow
```

## 🧪 Step 7: Test GitOps Workflow

```bash
# Create a test DAG
./test-dag-sync.py

# Commit and push the new DAG
cd ..
git add dags/dag_gitops_test_*.py
git commit -m "🔄 Add GitOps test DAG"
git push origin main

# Watch ArgoCD sync the change (within ~3 minutes)
kubectl get application airflow-gitops -n argocd -w
```

## 🧹 Step 8: Clean Up Sensitive Files

```bash
# Remove the file with sensitive data
rm argocd/airflow-application-with-secrets.yaml

# Verify it's gone
ls argocd/airflow-application-with-secrets.yaml  # Should show "No such file"
```

## 🎯 Final Result

After successful deployment:

- ✅ **ArgoCD**: Monitors your GitHub repo for changes
- ✅ **Airflow**: Runs with MySQL backend and S3 logging
- ✅ **GitOps**: New DAGs auto-deploy when pushed to Git
- ✅ **Security**: No sensitive data in Git repository
- ✅ **Auto-Sync**: Changes deploy automatically
- ✅ **Self-Healing**: Manual changes are reverted

## 🔄 Daily Workflow

1. **Add/modify DAGs** in `dags/` folder
2. **Commit and push** to GitHub
3. **ArgoCD detects** changes automatically  
4. **Airflow updates** with new DAGs
5. **New DAGs appear** in Airflow UI

## 🆘 Troubleshooting

### ArgoCD Sync Issues
```bash
# Force sync
kubectl patch application airflow-gitops -n argocd \
  -p '{"operation":{"sync":{}}}' --type merge

# Check sync logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server
```

### Airflow Pod Issues
```bash
# Check pod logs
kubectl logs -n airflow -l component=scheduler -c scheduler

# Check Git sync logs
kubectl logs -n airflow -l component=scheduler -c dags-git-sync
```

### Update Credentials
```bash
# Update sensitive values
./configure-sensitive-values.sh

# Apply updated configuration
kubectl apply -f airflow-application-with-secrets.yaml

# Clean up
rm airflow-application-with-secrets.yaml
```

---

## 🎉 Success!

Your Airflow is now fully GitOps managed with ArgoCD! 🚀

- **Secure**: No sensitive data in Git
- **Automated**: DAGs deploy automatically
- **Monitored**: Full visibility in ArgoCD UI
- **Scalable**: Easy to manage and update
