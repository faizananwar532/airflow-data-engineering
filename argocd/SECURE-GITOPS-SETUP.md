# Secure GitOps Setup for Airflow

This guide explains how to set up ArgoCD GitOps for Airflow while keeping sensitive data secure and out of your Git repository.

## 🔐 Security Approach

### ✅ **What's Safe to Commit:**
- `mysql-github-values-public.yaml` - Public Helm values with placeholder values
- `airflow-application.yaml` - ArgoCD Application template (with placeholders)
- All scripts and documentation

### ❌ **What Should NEVER be Committed:**
- `mysql-github-values.yaml` - Contains real AWS credentials and MySQL passwords
- `airflow-application-with-secrets.yaml` - Generated file with real sensitive values
- Any files with actual credentials, API keys, or passwords

**🛡️ Protection:** These files are automatically protected by `.gitignore` patterns:
```
# Sensitive Airflow configuration files
mysql-values.yaml
mysql-github-values.yaml

# ArgoCD files with sensitive data
airflow-application-with-secrets.yaml
*-with-secrets.yaml
```

## 🚀 **Secure Deployment Process**

### Step 1: Configure Sensitive Values
```bash
# Run the configuration script
./configure-sensitive-values.sh
```

This script will:
- Prompt for your sensitive values (MySQL, AWS, S3, Fernet key)
- Generate `airflow-application-with-secrets.yaml` with real values
- Keep sensitive data local only

### Step 2: Deploy via ArgoCD
```bash
# Deploy Airflow using GitOps
./deploy-airflow-gitops.sh
```

This script will:
- Use the secure configuration file if available
- Create necessary Kubernetes secrets
- Deploy the ArgoCD Application
- Monitor deployment status

### Step 3: Clean Up
```bash
# Remove the sensitive configuration file
rm airflow-application-with-secrets.yaml
```

## 📁 **File Structure**

```
argocd/
├── airflow-application.yaml              # Template (safe to commit)
├── mysql-github-values-public.yaml       # Public values (safe to commit)
├── configure-sensitive-values.sh         # Configuration script (safe to commit)
├── deploy-airflow-gitops.sh              # Deployment script (safe to commit)
├── airflow-application-with-secrets.yaml # Generated (DO NOT COMMIT)
└── SECURE-GITOPS-SETUP.md                # This documentation
```

## 🔄 **GitOps Workflow**

1. **Developer adds/modifies DAGs** in `dags/` folder
2. **Commits and pushes** to GitHub repository
3. **ArgoCD detects changes** automatically (within ~3 minutes)
4. **ArgoCD syncs changes** to Kubernetes
5. **Airflow pods restart** with new DAGs
6. **New DAGs appear** in Airflow UI automatically

## 🛡️ **Security Features**

### Sensitive Data Handling
- **Environment Variables**: Injected via ArgoCD Helm parameters
- **Kubernetes Secrets**: Created separately for database connections
- **Local Configuration**: Sensitive values stored locally, not in Git

### ArgoCD Security
- **Auto-Sync**: Enabled for automatic deployment
- **Self-Healing**: Manual changes are reverted automatically
- **Prune**: Deleted resources are removed automatically
- **Retry Logic**: Automatic recovery from sync failures

## 📋 **Environment Variables Injected**

The following sensitive values are injected at deployment time:

```yaml
# MySQL Connections
AIRFLOW_CONN_MYSQL: "mysql://user:pass@host:port/db"
AIRFLOW_CONN_MYSQL_DEFAULT: "mysql://user:pass@host:port/db"

# AWS Credentials
AWS_ACCESS_KEY_ID: "your-access-key"
AWS_SECRET_ACCESS_KEY: "your-secret-key"

# S3 Configuration
AIRFLOW__LOGGING__REMOTE_BASE_LOG_FOLDER: "s3://your-bucket/logs"

# Fernet Key
AIRFLOW__CORE__FERNET_KEY: "your-fernet-key"
```

## 🔧 **Customization**

### Update Sensitive Values
```bash
# Set environment variables before running the script
export MYSQL_CONNECTION="mysql://newuser:newpass@newhost:3306/newdb"
export AWS_ACCESS_KEY_ID="new-access-key"
export AWS_SECRET_ACCESS_KEY="new-secret-key"
export S3_LOG_BUCKET="s3://new-bucket/logs"
export FERNET_KEY="new-fernet-key"

# Run configuration script
./configure-sensitive-values.sh
```

### Manual ArgoCD Application Update
```bash
# Generate secure config
./configure-sensitive-values.sh

# Apply directly
kubectl apply -f airflow-application-with-secrets.yaml

# Clean up
rm airflow-application-with-secrets.yaml
```

## 🔍 **Monitoring and Troubleshooting**

### Check Application Status
```bash
# ArgoCD application status
kubectl get application airflow-gitops -n argocd

# Detailed application info
kubectl describe application airflow-gitops -n argocd

# Application sync status
kubectl get application airflow-gitops -n argocd -o jsonpath='{.status.sync.status}'
```

### Monitor Airflow Pods
```bash
# Watch pods restart during sync
kubectl get pods -n airflow -w

# Check pod logs
kubectl logs -n airflow -l component=scheduler -c dags-git-sync --tail=10
```

### Force Sync
```bash
# Trigger immediate sync
kubectl patch application airflow-gitops -n argocd \
  -p '{"operation":{"sync":{}}}' --type merge
```

## 🚨 **Security Best Practices**

### 1. Never Commit Sensitive Data
- Use `.gitignore` to exclude sensitive files
- Review commits before pushing
- Use `git-secrets` or similar tools to scan for credentials

### 2. Rotate Credentials Regularly
- Update MySQL passwords periodically
- Rotate AWS access keys
- Generate new Fernet keys when needed

### 3. Use Environment-Specific Values
- Different credentials for dev/staging/prod
- Separate S3 buckets per environment
- Environment-specific MySQL databases

### 4. Monitor Access
- Review ArgoCD audit logs
- Monitor Kubernetes RBAC access
- Set up alerts for unauthorized changes

## 🆘 **Emergency Procedures**

### Credential Compromise
```bash
# 1. Immediately rotate compromised credentials
# 2. Update configuration
./configure-sensitive-values.sh

# 3. Force sync new credentials
kubectl patch application airflow-gitops -n argocd \
  -p '{"operation":{"sync":{}}}' --type merge

# 4. Verify pods restart with new credentials
kubectl get pods -n airflow -w
```

### Rollback Deployment
```bash
# Get application history
kubectl get application airflow-gitops -n argocd -o yaml

# Rollback to previous version
kubectl patch application airflow-gitops -n argocd \
  -p '{"spec":{"source":{"targetRevision":"previous-commit-hash"}}}' --type merge
```

## ✅ **Verification Steps**

After deployment, verify:

1. **ArgoCD Application**: `kubectl get application airflow-gitops -n argocd`
2. **Airflow Pods**: `kubectl get pods -n airflow`
3. **DAG Sync**: Check ArgoCD UI for sync status
4. **Airflow UI**: Verify DAGs appear correctly
5. **Logs**: Check S3 bucket for log files

---

**Remember**: Security is a shared responsibility. Always follow your organization's security policies and best practices when handling sensitive data.
