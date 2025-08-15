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

  namespace        = "argocd"
  create_namespace = true

  values = [
    file("${path.module}/files/argocd-values.yaml")
  ]

  depends_on = [
    kubernetes_namespace.all
  ]
}

resource "kubernetes_namespace" "all" {
  for_each = toset(var.namespaces)

  metadata {
    name = each.value
  }
}
