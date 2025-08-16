terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "minikube"
}

provider "helm" {
  kubernetes = {
    config_path    = "~/.kube/config"
    config_context = "minikube"
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "8.3.0"

  namespace        = "argocd"
  create_namespace = true

  values = [
    file("${path.module}/files/argocd-values.yaml")
  ]
}

resource "helm_release" "monitoring" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "76.4.0"

  namespace        = "monitoring"
  create_namespace = true

  values = [
    file("${path.module}/files/kube-prometheus-stack-values.yaml")
  ]
}

resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = "3.13.0"

  namespace        = "metrics-server"
  create_namespace = true

  values = [
    file("${path.module}/files/metrics-server-values.yaml")
  ]
}

resource "kubernetes_namespace" "all" {
  for_each = toset(var.namespaces)

  metadata {
    name = each.value
  }
}
