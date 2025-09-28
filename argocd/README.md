# ArgoCD Installation and Setup

This directory contains the configuration files and scripts to install ArgoCD in your Kubernetes cluster with LoadBalancer service type for external access.

## 📋 Overview

ArgoCD is a declarative, GitOps continuous delivery tool for Kubernetes. This setup includes:

- **ArgoCD Core Components**: Server, Repository Server, Application Controller
- **LoadBalancer Service**: For external access to ArgoCD UI
- **AWS ELB Integration**: Optimized for AWS EKS clusters
- **Automated Installation**: One-command setup script

## 📁 Files Structure

```
argocd/
├── namespace.yaml                    # ArgoCD namespace
├── argocd-server-loadbalancer.yaml   # LoadBalancer service
├── install-argocd.sh                 # Installation script
└── README.md                         # This documentation
```

## 🚀 Quick Installation

### Prerequisites

- Kubernetes cluster (EKS recommended)
- `kubectl` configured and connected to your cluster
- Proper IAM permissions for LoadBalancer creation (if using AWS)

### Installation Steps

1. **Navigate to ArgoCD directory:**
   ```bash
   cd airflow-data-engineering/argocd
   ```

2. **Run the installation script:**
   ```bash
   ./install-argocd.sh
   ```

3. **Wait for completion** - The script will:
   - Create the `argocd` namespace
   - Install ArgoCD core components
   - Create LoadBalancer service
   - Wait for external IP assignment
   - Display access credentials

## 🌐 Accessing ArgoCD

After installation, you'll get output similar to:

```
✅ ArgoCD installation completed successfully! 🚀

Access Information:
===================
🌐 ArgoCD UI: http://your-loadbalancer-hostname
🌐 ArgoCD UI (HTTPS): https://your-loadbalancer-hostname
👤 Username: admin
🔑 Password: randomly-generated-password
```

### Default Credentials

- **Username**: `admin`
- **Password**: Retrieved automatically from `argocd-initial-admin-secret`

## 📋 Manual Installation (Alternative)

If you prefer manual installation:

1. **Create namespace:**
   ```bash
   kubectl apply -f namespace.yaml
   ```

2. **Install ArgoCD:**
   ```bash
   kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
   ```

3. **Create LoadBalancer service:**
   ```bash
   kubectl apply -f argocd-server-loadbalancer.yaml
   ```

4. **Get admin password:**
   ```bash
   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
   ```

## 🔧 Configuration Details

### LoadBalancer Service Configuration

The `argocd-server-loadbalancer.yaml` includes AWS-specific annotations:

- **Network Load Balancer (NLB)**: For better performance
- **Internet-facing**: Public access
- **Cross-zone load balancing**: High availability
- **TCP backend protocol**: For gRPC support

### Ports Configuration

- **Port 80**: HTTP access to ArgoCD UI
- **Port 443**: HTTPS/gRPC access (can be configured for SSL termination)

## 🛠️ Useful Commands

### Check Installation Status
```bash
# Check ArgoCD pods
kubectl get pods -n argocd

# Check LoadBalancer service
kubectl get svc argocd-server-loadbalancer -n argocd

# Check all ArgoCD resources
kubectl get all -n argocd
```

### Access ArgoCD
```bash
# Get LoadBalancer external IP/hostname
kubectl get svc argocd-server-loadbalancer -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d

# Port forward (alternative access method)
kubectl port-forward svc/argocd-server-loadbalancer 8080:80 -n argocd
```

### Monitor ArgoCD
```bash
# Watch ArgoCD pods
kubectl get pods -n argocd -w

# Check ArgoCD server logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server -f

# Check application controller logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller -f
```

## 🔐 Security Considerations

### Initial Setup
1. **Change default password** immediately after first login
2. **Enable RBAC** for user management
3. **Configure OIDC/SSO** for enterprise authentication
4. **Set up proper SSL certificates** for production use

### Network Security
- LoadBalancer is internet-facing by default
- Consider using ingress with SSL termination for production
- Implement network policies if required
- Use security groups to restrict access

## 🔧 Troubleshooting

### Common Issues

1. **LoadBalancer Pending External IP**
   ```bash
   # Check LoadBalancer status
   kubectl describe svc argocd-server-loadbalancer -n argocd
   
   # Verify AWS Load Balancer Controller is installed
   kubectl get pods -n kube-system | grep aws-load-balancer-controller
   ```

2. **ArgoCD Pods Not Ready**
   ```bash
   # Check pod status
   kubectl get pods -n argocd
   
   # Check pod logs
   kubectl logs -n argocd <pod-name>
   
   # Describe problematic pod
   kubectl describe pod -n argocd <pod-name>
   ```

3. **Cannot Access ArgoCD UI**
   ```bash
   # Verify LoadBalancer service
   kubectl get svc argocd-server-loadbalancer -n argocd
   
   # Check security groups (AWS)
   # Ensure ports 80/443 are open from your IP
   
   # Try port forwarding as alternative
   kubectl port-forward svc/argocd-server 8080:80 -n argocd
   ```

4. **Admin Password Not Working**
   ```bash
   # Get current admin password
   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
   
   # Reset admin password (if needed)
   kubectl -n argocd patch secret argocd-secret -p '{"stringData": {"admin.password": "$2a$10$rRyBsGSHK6.uc8fntPwVIuLVHgsAhAX7TcdrqW/RADU0uh7CaChLa", "admin.passwordMtime": "'$(date +%FT%T%Z)'"}}'
   ```

## 🚀 Next Steps

After ArgoCD is installed and accessible:

1. **Login to ArgoCD UI** using the provided credentials
2. **Change the admin password** in Settings > Accounts
3. **Connect your Git repositories** in Settings > Repositories  
4. **Create your first Application** to deploy workloads
5. **Set up RBAC** for team access management
6. **Configure notifications** for deployment events

## 📚 Additional Resources

- [ArgoCD Official Documentation](https://argo-cd.readthedocs.io/)
- [ArgoCD Getting Started Guide](https://argo-cd.readthedocs.io/en/stable/getting_started/)
- [GitOps Best Practices](https://argo-cd.readthedocs.io/en/stable/user-guide/best_practices/)
- [ArgoCD Configuration Management](https://argo-cd.readthedocs.io/en/stable/operator-manual/)

## 🔄 Uninstallation

To remove ArgoCD completely:

```bash
# Delete ArgoCD resources
kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Delete LoadBalancer service
kubectl delete -f argocd-server-loadbalancer.yaml

# Delete namespace (this will remove all remaining resources)
kubectl delete -f namespace.yaml
```

---

**Note**: This setup is optimized for AWS EKS clusters. For other cloud providers, you may need to adjust the LoadBalancer annotations in `argocd-server-loadbalancer.yaml`.
