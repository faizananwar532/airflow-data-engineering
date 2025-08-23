# Airflow Data Engineering Platform

A comprehensive Apache Airflow deployment on AWS EKS with multiple DAG synchronization methods, MySQL backend, and S3 integration.

## 🏗️ Architecture Overview

- **Platform**: Apache Airflow 2.9.3 on AWS EKS
- **Database**: External MySQL 8.0 (EC2 instance)
- **Storage**: S3 for logs and DAG storage
- **Networking**: LoadBalancer service for external access
- **Sync Methods**: S3 sync, GitHub sync, and Helm packaging

## 📁 Project Structure

```
airflow-data-engineering/
├── airflow-1.15/              # Helm chart and configurations
│   ├── mysql-values.yaml      # S3 sync configuration
│   ├── mysql-github-values.yaml # GitHub sync configuration
│   └── airflow-advanced-test-dag-configmap.yaml
├── dags/                      # DAG files
│   ├── dag_github_sync_verification.py
│   ├── dag_github_mysql_etl.py
│   ├── dag_s3_to_mysql_etl.py
│   └── dag_advanced_test.py
├── scripts/                   # Deployment and utility scripts
│   ├── deploy-with-github-sync.sh
│   ├── reset-airflow.sh
│   ├── clean-mysql-db.sh
│   └── add_mysql_connection.py
├── mysql/                     # MySQL Docker setup
│   └── docker-compose.yml
└── terraform/                 # Infrastructure as code
```

## 🎯 Completed Objectives

### ✅ 1. EKS Cluster with LoadBalancer
- AWS EKS cluster deployed
- LoadBalancer service for external Airflow access
- **Status**: Completed

### ✅ 2. Airflow with S3 Integration
- Airflow deployed via Helm chart
- S3 bucket for remote logging (`airflow-logs-ravi`)
- No EFS dependency
- **Status**: Completed

### ✅ 3. S3 DAG Synchronization
- DAGs stored in S3 bucket (`airflow-dags-ravi`)
- Automatic sync from S3 to Airflow
- **Status**: Completed

### ✅ 4. GitHub DAG Synchronization
- Direct GitHub to Airflow sync
- Git sidecar containers for automatic pulling
- **Status**: Completed ✨

### ✅ 5. Helm-Packaged DAGs
- DAGs packaged with Helm chart
- Deployed via ConfigMaps during installation
- **Status**: Completed

### ✅ 6. External MySQL Database
- MySQL 8.0 running on EC2 instance
- Airflow metadata and result backend
- **Status**: Completed

### ✅ 7. LoadBalancer Exposure
- Airflow UI accessible via AWS LoadBalancer
- External IP with port 8080
- **Status**: Completed

## 🔄 DAG Synchronization Methods

### Method 1: S3 Sync (Legacy)

**Configuration**: `mysql-values.yaml`

**How it works**:
1. Upload DAGs to S3 bucket `airflow-dags-ravi`
2. S3 sync sidecar containers pull DAGs every 60 seconds
3. DAGs appear in Airflow automatically

**Setup Steps**:
```bash
# Deploy with S3 sync
./scripts/reset-airflow.sh

# Upload DAGs to S3
aws s3 cp dags/your_dag.py s3://airflow-dags-ravi/
```

**Pros**: Simple, works with any S3 client
**Cons**: Manual upload required, no version control integration

---

### Method 2: GitHub Sync (Current) ⭐

**Configuration**: `mysql-github-values.yaml`

**How it works**:
1. Create/modify DAGs in `dags/` folder
2. Commit and push to GitHub repository
3. Git sidecar containers clone from GitHub every 60 seconds
4. DAGs sync automatically to Airflow

**Setup Steps**:
```bash
# Deploy with GitHub sync
export AWS_ACCESS_KEY_ID="your_key"
export AWS_SECRET_ACCESS_KEY="your_secret"
./scripts/deploy-with-github-sync.sh

# Add new DAGs
echo "# Your new DAG" > dags/my_new_dag.py
git add dags/my_new_dag.py
git commit -m "Add new DAG"
git push origin main

# DAG appears in Airflow within 60 seconds
```

**Configuration Details**:
- **Repository**: `https://github.com/faizananwar532/airflow-data-engineering.git`
- **Branch**: `main`
- **Sync Interval**: 60 seconds
- **Sync Path**: `dags/` folder

**Pros**: 
- ✅ Version control integration
- ✅ Automatic sync from Git
- ✅ No manual upload needed
- ✅ Collaboration friendly

**Cons**: Requires Git repository setup

---

### Method 3: Helm-Packaged DAGs

**Configuration**: ConfigMaps in Helm chart

**How it works**:
1. DAGs defined in ConfigMaps (e.g., `airflow-advanced-test-dag-configmap.yaml`)
2. Mounted as files during Helm deployment
3. Available immediately upon installation

**Setup Steps**:
```bash
# Create ConfigMap for DAG
kubectl apply -f airflow-1.15/airflow-advanced-test-dag-configmap.yaml -n airflow

# Deploy/upgrade Helm chart
helm upgrade air airflow-1.15 --namespace airflow --values airflow-1.15/mysql-github-values.yaml
```

**Example ConfigMap**:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: airflow-advanced-test-dag
data:
  dag_advanced_test.py: |
    from airflow import DAG
    # Your DAG code here
```

**Pros**: Immediate availability, version controlled with chart
**Cons**: Requires Helm upgrade for changes

## 🗄️ Database Setup

### External MySQL Configuration

**Location**: EC2 instance `54.167.107.216:3306`
**Database**: `mydb`
**User**: `myuser` / `mypassword`

**Docker Setup** (`mysql/docker-compose.yml`):
```yaml
version: '3.8'
services:
  mysql:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: rootpassword
      MYSQL_DATABASE: mydb
      MYSQL_USER: myuser
      MYSQL_PASSWORD: mypassword
    ports:
      - "3306:3306"
```

**Connection Test**:
```bash
mysql -h 54.167.107.216 -u myuser -pmypassword mydb -e "SELECT VERSION();"
```

## 🚀 Deployment Guide

### Quick Start (GitHub Sync - Recommended)

1. **Set Environment Variables**:
```bash
export AWS_ACCESS_KEY_ID="your_aws_key"
export AWS_SECRET_ACCESS_KEY="your_aws_secret"
```

2. **Deploy Airflow**:
```bash
cd scripts
./deploy-with-github-sync.sh
```

3. **Access Airflow UI**:
```
URL: http://a7135228a9de74d61973edf46bdf9acc-1119185433.us-east-1.elb.amazonaws.com:8080
Username: admin
Password: admin
```

4. **Add New DAGs**:
```bash
# Create new DAG
echo "# Your DAG code" > dags/my_dag.py

# Push to GitHub
git add dags/my_dag.py
git commit -m "Add my_dag"
git push origin main

# Wait 60 seconds - DAG appears in Airflow!
```

### Full Deployment (Clean Install)

1. **Clean Database** (if needed):
```bash
./scripts/clean-mysql-db.sh
```

2. **Deploy Airflow**:
```bash
./scripts/reset-airflow.sh  # For S3 sync
# OR
./scripts/deploy-with-github-sync.sh  # For GitHub sync
```

3. **Verify Deployment**:
```bash
kubectl get pods -n airflow
kubectl logs -n airflow -l component=scheduler -c dags-git-sync --tail=10
```

## 🛠️ Troubleshooting

### Common Issues

#### 1. Fernet Key Mismatch Error

**Error**:
```
cryptography.fernet.InvalidToken
```

**Cause**: Fernet key changed between deployments, old encrypted connections can't be decrypted

**Solution**:
```bash
# Clean the database to remove old encrypted data
./scripts/clean-mysql-db.sh

# Redeploy with consistent Fernet key
./scripts/deploy-with-github-sync.sh
```

**Prevention**: Always use the same Fernet key in your values file:
```yaml
env:
  - name: AIRFLOW__CORE__FERNET_KEY
    value: "46BKJoQYlPPOexq0OhDZnIlNepKFf87WFwLbfzqDDho="
```

#### 2. DAGs Not Syncing from GitHub

**Check Git Sync Logs**:
```bash
kubectl logs -n airflow -l component=scheduler -c dags-git-sync --tail=20
```

**Common Solutions**:
- Verify repository URL in `mysql-github-values.yaml`
- Check if repository is public or SSH keys are configured
- Ensure `dags/` folder exists in repository
- Wait up to 60 seconds for sync interval

#### 3. MySQL Connection Issues

**Test Connection**:
```bash
mysql -h 54.167.107.216 -u myuser -pmypassword mydb -e "SHOW TABLES;"
```

**Add Connection in Airflow UI**:
1. Go to Admin → Connections
2. Add new connection:
   - Conn Id: `mysql`
   - Conn Type: `MySQL`
   - Host: `54.167.107.216`
   - Schema: `mydb`
   - Login: `myuser`
   - Password: `mypassword`
   - Port: `3306`

#### 4. Helm Upgrade Failures

**Error**: Environment variable order conflicts

**Solution**: Use fresh installation instead of upgrade:
```bash
helm uninstall air -n airflow
./scripts/deploy-with-github-sync.sh
```

#### 5. GitHub Security Scanning

**Error**: "Push cannot contain secrets"

**Solution**: Use placeholder values in committed files:
```yaml
env:
  - name: AWS_ACCESS_KEY_ID
    value: "YOUR_AWS_ACCESS_KEY_ID"
```

Set real values via environment variables during deployment.

## 📊 Monitoring

### Check Deployment Status
```bash
# Pod status
kubectl get pods -n airflow

# Service status  
kubectl get svc -n airflow

# Git sync logs
kubectl logs -n airflow -l component=scheduler -c dags-git-sync --follow
```

### Verify DAG Loading
```bash
# Check if DAG is loaded
kubectl exec -n airflow <scheduler-pod> -c scheduler -- python -c "
from airflow.models import DagBag
dag_bag = DagBag()
print('Loaded DAGs:', list(dag_bag.dags.keys()))
"
```

## 🔮 Future Enhancements

### 🚧 Pending Objectives

- **CI/CD Pipeline**: Automated deployment when DAGs change (Objective #6)
- **ArgoCD Integration**: GitOps for infrastructure management (Objective #7)

### Potential Improvements

- **Private Repository Support**: SSH key configuration for private GitHub repos
- **Multi-environment**: Dev/staging/prod configurations
- **Monitoring**: Prometheus/Grafana integration
- **Security**: Vault integration for secrets management
- **Scaling**: HPA for worker nodes

## 📚 Additional Resources

- [Airflow Documentation](https://airflow.apache.org/docs/)
- [Helm Chart Documentation](./airflow-1.15/README.md)
- [Direct GitHub Sync Guide](./DIRECT_GITHUB_SYNC.md)
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with the verification DAG
5. Submit a pull request

---

**Last Updated**: August 2024  
**Airflow Version**: 2.9.3  
**Kubernetes**: AWS EKS  
**Status**: Production Ready ✅