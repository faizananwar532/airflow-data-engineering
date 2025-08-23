#### cluster resources
data "aws_eks_cluster" "stagingCluster" {
  name = var.clustername
}

data "aws_eks_cluster_auth" "clusterAuth" {
  name = var.clustername
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.stagingCluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.stagingCluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.clusterAuth.token
  # load_config_file       = false
}

provider "helm" {
  kubernetes = {
    config_path = "~/.kube/config"
  }
}

# Nginx ingress controller
resource "helm_release" "ingress_nginx" {
  name       = "opeth"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"

  set = [
    {
    name  = "controller.metrics.enabled"
    value = "true"
    },
    {
      name  = "controller.metrics.service.annotations.prometheus\\.io/scrape"
      value = "true"
      type  = "string"
    },
    {
      name  = "controller.metrics.service.annotations.prometheus\\.io/port"
      value = "10254"
      type  = "string"
    },
    {
      name  = "defaultBackend.enabled"
      value = "true"
    },
    {
      name  = "controller.service.type"
      value = "LoadBalancer"
    },
    {
      name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-backend-protocol"
      value = "tcp"
      type  = "string"
    },
    {
      name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-cross-zone-load-balancing-enabled"
      value = "true"
    },
    {
      name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
      value = "nlb"
      type  = "string"
    }
  ]
}