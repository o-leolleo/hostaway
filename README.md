# DevOps Engineer Task - Hostaway

Welcome! This exercise will assess your practical DevOps skills. Please follow the instructions below. **All components must run locally—no hosted/cloud solutions.**

---

## Task Overview

1. Set up a local Kubernetes cluster using Minikube.
2. Use Terraform to provision the cluster with separate namespaces for internal vs external applications and any different environments.
3. Install ArgoCD on the cluster using Helm.
4. Demonstrate GitOps workflows with ArgoCD:
  - Deploy a simple Nginx app with output "hello it's me"
  - We should be able to deploy a new version to staging, promote it to production, rollback to any version.
5. Define key monitoring metrics and thresholds (can be in README). For each, specify:
  - What to monitor.
  - The threshold for alerting.
  - Why it’s important.


## Deliverables

- All code (Terraform, Helm charts, manifests, app code) in a GitHub repository.
- A `README.md` with:
  - Setup instructions (including prerequisites). Should be a 1 command install and run.
  - How to use ArgoCD for deployments, promotions, and rollbacks.
  - Defined monitors and thresholds.

## Notes

- **Do not use any managed/cloud services.** Everything must run locally.
- If you encounter issues, document your troubleshooting steps.

Good luck! If you have any questions, please reach out by email.