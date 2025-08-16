# DevOps Engineer Task - Hostaway

This repository contains the code and instructions for the [DevOps Engineer task for Hostaway](https://github.com/hostvasco/devops-task/tree/main).

## Setup instructions

Pre-requisites:
- [argocd cli](https://argo-cd.readthedocs.io/en/stable/cli_installation/) (>= 3.1.0, previous versions should work)
- [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)
- [kustomize](https://kubectl.docs.kubernetes.io/installation/kustomize/)
- [terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) (I'm using v1.12.2, previous version should work)
- [make](https://www.gnu.org/software/make/) (Normally available in Linux or MacOS)
- [pre-commit](https://pre-commit.com/#install)
- [docker + docker desktop (or similar)](https://docs.docker.com/engine/install/)
- [minikube](https://minikube.sigs.k8s.io/docs/start/?arch=%2Fmacos%2Farm64%2Fstable%2Fbinary+download)

With all the above installed, you should be able to run the below, to have a local env up & running.
```shell
make
# or
make up
```

This setup runs:
- ArgoCD under http://localhost:20080
- Prometheus at http://localhost:9090
- Hostaway NGINX apps:
  - stg: http://localhost:8070
  - prd: http://localhost:8090

What is `make` doing?
1. Minikube is started in case not running.
2. Terraform apply is run in auto-approve mode, to create a few namespaces and to install the `argocd`, `metrics-server` and `kube-prometheus-stack` helm charts.
3. Kustomize is used to bootstrap the argocd server configs (I'm following the GitOps directory structure discussed [here](https://developers.redhat.com/articles/2022/09/07/how-set-your-gitops-directory-structure))
4. A `hostaway:latest` image is built and made available to Minikube.
5. The access infos are echoed out.

Once you're done you can run `make clean` to tear down the minikube cluster (this assume you have only one cluster running, it'll delete all clusters in case you have more).

## How to use ArgoCD for deployments, promotions, and rollbacks

To deploy something via ArgoCD, in this setup, you add a new tenant to the [./gitops/tenants/](./gitops/tenants/) directory, following the existing structure. For the example kustomize application (`hostaway`), there is a base folder for common constructs, and an overlay folder for each environment, in our case `stg` and `prd` (staging and production, respectively).

Each overlay is converted to an ArgoCD application via the [`tenants-appset.yaml`](./gitops/components/applicationsets/tenants-appset.yaml) Application Set. These are created via the bootstrap process discussed in the previous section.

Promoting a version of the app to any env is a matter of having the appropriate container image (and tag) created and available to the cluster, and editing the overlay `kustomization.yaml` file `images` property accordingly. This is often automated by calling the kustomize command like `kustomize edit set image "hostaway=*:<version>"`.
After this change to the kustomization file is committed to the git (local) repository, ArgoCD will detect the change ([default sync pool of 180s](https://argo-cd.readthedocs.io/en/stable/faq/#how-often-does-argo-cd-check-for-changes-to-my-git-or-helm-repository)) and apply it automatically, or you can trigger a sync manually via the ArgoCD UI or CLI. When using git hosts like GitHub or GitLab this sync trigger is often performed via [ArgoCD webhook call](https://argo-cd.readthedocs.io/en/stable/operator-manual/webhook/).

These commits to the right overlays kustomization files can be done in a fashion such that an image built and deployed to staging is later re-tagged with a SemVer which is then reflected in the prd overlay kustomization file (via regular commit).

A rollback to a previous version is again just a matter of editing the image tag in the kustomization files, via any commit (normally a revert), which can be done via an automated pipelines or just editing the right files and pushing to the remote repository.

I've added a make command to simulate this process, although here I'm not promoting images by relabeling but rather building them:

```shell
# this will build a new image and update the stg (staging) kustomization files accordingly
make deploy env=stg version=sha-12345
# this will do the same, but for production (prd overlay)
make deploy env=prd version=v1.0.0
```

## Defined monitors and thresholds

Monitoring is one of my _known-unknown_ areas, where I feel there is the most room for improvement. My approach here was to go through the metrics (and alerts) defined by default in the `kube-prometheus-stack` helm chart and picking the most important ones in my perspective.
The full list of default alerts, installed by the helm chart, is available at http://localhost:9090/alerts after running this project. Most of the discussion below is either a quote or adaptation of the underlying docs provided in https://runbooks.prometheus-operator.dev/, for the mentioned alerts, its metrics, and thresholds.

- Cluster related
  - KubeApiDown
    - **Threshold**: 15 minutes of downtime.
    - **Why it’s important**: The API server is a critical component of the Kubernetes control plane. If it's down, the entire cluster is potentially unavailable.
  - KubeProxyDown
    - **Threshold**: 15 minutes of downtime, when all instances have not been able to be reachable by the monitoring system.
    - **Why it’s important**: The Kube Proxy is responsible for network routing and load balancing in the cluster. If it's down, services may become unreachable.
  - KubeletDown
    - **Threshold**: 15 minutes of downtime.
    - **Why it’s important**: The Kubelet is responsible for managing pods on each node. If it's down it can lead to critical service disruptions.
  - KubeSchedulerDown
    - **Threshold**: 15 minutes of downtime.
    - **Why it’s important**: The Kube Scheduler is responsible for scheduling pods onto nodes. If it's down, new pods may not be scheduled, leading to potential service disruptions. The cluster might be partially or fully non-functional.
  - KubeletTooManyPods
    - **Threshold**: More than 95% of node's pod capacity, 110 by default, for 15 minutes.
    - **Why it’s important**: The Kubelet has a limit on the number of pods it can manage. If this limit is reached, new pods may not be scheduled on the node, leading to potential service disruptions.
- Node related
  - KubeNodeNotReady
    - **Threshold**: Unready for 15 minutes.
    - **Why it’s important**: A node being not ready can indicate underlying issues with the node, such as resource exhaustion or network connectivity problems.
  - KubeNodePressure
    - **Threshold**: 15 minutes of high resource usage (CPU, memory, disk).
    - **Why it’s important**: Node pressure can lead to pod eviction and scheduling issues, impacting the availability of applications running on the node.
  - KubeNodeUnreachable
    - **Threshold**: Unreachable for 15 minutes.
    - **Why it’s important**: If a node becomes unreachable, it can indicate network issues or node failures. This can lead to pod eviction and scheduling issues.
  - NodeFileSystemSpaceFillingUp
    - **Threshold**: Available file system space below 15% and is predicted to fill up in less than 4h, for 1 hour.
    - **Why it’s important**: If a node's file system is filling up, it can lead to pod eviction and scheduling issues, impacting the availability of applications running on the node.
  - NodeFileDescriptorLimit
    - **Threshold**: 15 minutes of file descriptor usage over 90%.
    - **Why it’s important**: Applications on the node may no longer be able to open and operate files.
- Workloads related
  - KubeDaemonSetNotScheduled
    - **Threshold**: More than one DaemonSet that has pods not scheduled on all allowed nodes for 10m.
    - **Why it’s important**: This affects the availability of critical system services that rely on DaemonSets, and can indicate missing tolerations or node affinity issues. E.g. DaemonSets attempting to get scheduled to fargate nodes, missing tolerations of node taints for DS pods that must run during node taint/drain.
  - KubePodNotReady
    - **Threshold**: at least 1 pod in a Non-Ready state for 15 minutes.
    - **Why it’s important**: This might indicate service degradation or unavailability, might also indicate underlying issues with node autoscaling and cluster capacity.
  - KubePodCrashLooping
    - **Threshold**: at least 1 pod in CrashLoopBackOff state in the last 5 minutes.
    - **Why it’s important**: This metric helps to identify problematic pods that are crashing and restarting frequently, which can indicate underlying issues with the application or its configuration.
  - KubeHpaMaxedOut
    - **Threshold**: at least 1 Horizontal Pod Autoscaler (HPA) is maxed out for 15 minutes.
    - **Why it’s important**: This indicates that the application is experiencing high load and cannot scale further, potentially leading to performance degradation.
  - KubeDeploymentReplicasMismatch (+ StatefulSet replica mismatch, in case running them)
    - **Threshold**: More than one deployment where replicas mismatch the desired for 15 minutes.
    - **Why it’s important**: This metric helps to identify deployments that are not meeting their desired state, causing service degradation or unavailability.
  - KubeJobFailed
    - **Threshold**: More than one job failed in the last 15 minutes.
    - **Why it’s important**: Can indicate essential jobs that are not completing successfully, potentially impacting application functionality. E.g. migrations, cleanups, etc.
  - KubeJobNotCompleted
    - **Threshold**: More than one job not completed in the last 1 hour.
    - **Why it’s important**: Can indicate long running jobs or issues with scheduling the next one.

## Notes

This took longer as initially I went straight to hosting things into GitHub and adding actions to create tags and promote images. Shamefully I've extended the "Do not use any managed/cloud services." to "Do not use any managed/cloud services. But GitHub ones.". In case curious, the workflows are still available in this repo and should be working, although I've stubbed out the deploy jobs in order to not change the repository contents (I was doing circular commits updating the gitops files, just to illustrate, normally I'd host the gitops repo separately).

I've since backtracked on this approach and went finally to a full-local setup. Life's got simpler and more consistent.
