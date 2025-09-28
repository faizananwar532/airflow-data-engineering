# 🚀 Airflow GitOps - Quick Reference Card

## **📋 First Time Setup (5 Commands)**

```bash
cd airflow-data-engineering/argocd

# 1. Install ArgoCD
./install-argocd.sh

# 2. Set your credentials
export MYSQL_CONNECTION="mysql://myuser:mypassword@54.167.107.216:3306/mydb"
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
export S3_LOG_BUCKET="s3://your-bucket/logs"
export FERNET_KEY="your-fernet-key"
./configure-sensitive-values.sh

# 3. Deploy Airflow
./deploy-airflow-gitops.sh && rm airflow-application-with-secrets.yaml

# 4. Get access info
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
kubectl get svc -n argocd -n airflow
```

## **🔑 Access Information**

| Service | URL Command | Login |
|---------|-------------|-------|
| **ArgoCD** | `kubectl get svc argocd-server-loadbalancer -n argocd` | admin / [secret above] |
| **Airflow** | `kubectl get svc airflow-gitops-webserver -n airflow` | admin / admin |

## **📊 Monitoring Commands**

```bash
# Check everything is running
kubectl get pods -n argocd -n airflow

# Check ArgoCD sync status  
kubectl get application airflow-gitops -n argocd

# Check DAG sync logs
kubectl logs -n airflow -l component=scheduler -c dags-git-sync --tail=5

# Force sync
kubectl patch application airflow-gitops -n argocd -p '{"operation":{"sync":{}}}' --type merge
```

## **🔄 Daily GitOps Workflow**

1. **Add DAG**: Create `.py` file in `dags/` folder
2. **Commit**: `git add . && git commit -m "Add new DAG" && git push`
3. **Wait**: ArgoCD syncs automatically (3 minutes)
4. **Verify**: Check Airflow UI for new DAG

## **🆘 Quick Fixes**

```bash
# Pods not starting
kubectl logs -n airflow [pod-name] --previous

# Reset everything
kubectl delete namespace airflow argocd --ignore-not-found=true

# MySQL connection issues
kubectl get secret airflow-mysql-metadata -n airflow -o yaml

# Port forward if LoadBalancer pending
kubectl port-forward svc/airflow-gitops-webserver 8080:8080 -n airflow
```

## **📁 Key Files**

- `argocd/install-argocd.sh` - Install ArgoCD
- `argocd/configure-sensitive-values.sh` - Set credentials  
- `argocd/deploy-airflow-gitops.sh` - Deploy Airflow
- `dags/` - Your DAG files (auto-sync to Airflow)
- `.gitignore` - Protects sensitive files

## **🎯 Architecture**

```
GitHub → ArgoCD → Kubernetes → Airflow Pods → MySQL (EC2)
                                    ↓
                              S3 Logs + DAG Sync
```

**Total Setup Time**: ~15 minutes | **Components**: ArgoCD + Airflow + MySQL + S3 + GitOps
