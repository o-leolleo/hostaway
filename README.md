# DevOps Engineer Task - Hostaway

**All components must run locally—no hosted/cloud solutions.**

## Setup instructions
<!-- Setup instructions (including prerequisites). Should be a 1 command install and run. -->

## How to use ArgoCD for deployments, promotions, and rollbacks
<!-- 4. Demonstrate GitOps workflows with ArgoCD:
  - Deploy a simple Nginx app with output "hello it's me"
  - We should be able to deploy a new version to staging, promote it to production, rollback to any version. -->

## Defined monitors and thresholds

Monitoring is one of my _known-unknown_ areas, where I feel there is the most room for improvement. My approach here was to go through the metrics (and alerts) defined by default in the `kube-prometheus-stack` helm chart and picking the most important ones in my perspective.
The full list of default alerts, installed by the helm chart, is available at `http://localhost:9090/alerts` after running this project. Most of the discussion below is either a quote or adaptation of the underlying docs provided in https://runbooks.prometheus-operator.dev/, for the mentioned alerts, its metrics, and thresholds.

- Cluster related
  - KubeApiDown
    - **Threshold**: 15 minute of downtime.
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
