# Kubernetes Production Readiness Lab

A reproducible, hands-on Kubernetes lab demonstrating why
a successful Deployment does not necessarily mean an
application is production-ready.

The lab explores four failure scenarios:

1. Business functionality fails while readiness remains healthy.
2. A Pod becomes unready without restarting its container.
3. A rolling update stalls while the previous version remains available.
4. A failed liveness probe triggers a container restart.

## Architecture

- Kubernetes cluster: Kind
- Application: Python HTTP server
- Workload: Kubernetes Deployment
- Networking: ClusterIP Service and EndpointSlices
- Health checks: startup, readiness and liveness probes

See [Architecture](docs/architecture.md).

## Tested environment

The original experiments were verified on:

- Kubernetes server: v1.37.0
- kubectl: v1.37.2
- Kind: v0.33.0
- Docker: v29.10.0
- Host: Ubuntu 24.04

Results are documented in
[Verified Results](docs/verified-results.md).

## Requirements

- Linux, macOS or Windows with Docker
- Kind
- kubectl
- Sufficient resources for two application Pods

## Quick start

Create an isolated cluster:

```bash
mkdir -p "$HOME/.kube"

export KUBECONFIG="$HOME/.kube/readiness-lab-kind.yaml"

kind create cluster \
  --name readiness-lab \
  --image kindest/node:v1.37.0 \
  --kubeconfig "$KUBECONFIG" \
  --wait 180s
```

Verify the context:

```bash
kubectl config current-context
```

Expected:

```text
kind-readiness-lab
```

Deploy the application:

```bash
kubectl apply -f manifests/readiness-lab.yaml

kubectl -n readiness-lab rollout status \
  deployment/readiness-demo \
  --timeout=240s
```

Inspect the workload:

```bash
kubectl -n readiness-lab get deployments,pods,svc
```

## Verify the healthy application

Run:

```bash
./scripts/verify.sh
```

The script checks the cluster context, rollout status,
application endpoints and EndpointSlice conditions.

It does not intentionally modify cluster resources.

## Run the experiments

See [Experiments](docs/experiments.md).

The experiments intentionally introduce failures.
Use only the isolated Kind cluster.

## Cleanup

Remove the lab namespace:

```bash
kubectl delete namespace readiness-lab
```

Optionally delete the entire Kind cluster:

```bash
kind delete cluster --name readiness-lab
```

## Important limitations

This lab is designed for education and reproducibility.

It is not a production-ready application template.

The example uses a minimal Python container and does not
implement all recommended workload security controls.

Successful health checks cannot guarantee the correctness
of business-critical operations.

## Documentation

- [Architecture](docs/architecture.md)
- [Experiments](docs/experiments.md)
- [Verified Results](docs/verified-results.md)

## Author

Rafa Terrero

Senior Platform Engineer | Cloud Reliability & AI Infrastructure
