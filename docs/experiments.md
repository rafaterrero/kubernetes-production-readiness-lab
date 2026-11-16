# Reproducible Experiments

All experiments must run against the disposable Kind cluster.

Before starting:

```bash
export KUBECONFIG="$HOME/.kube/readiness-lab-kind.yaml"
kubectl config current-context
```

The expected context is `kind-readiness-lab`.

## 1. Business failure with successful readiness

Inject the simulated failure:

```bash
kubectl -n readiness-lab exec \
  deployment/readiness-demo \
  -- touch /tmp/checkout-down
```

The application now reports:

- /ready: HTTP 200
- /checkout: HTTP 503

The Deployment may still report 1/1 available.

Restore functionality:

```bash
kubectl -n readiness-lab exec \
  deployment/readiness-demo \
  -- rm /tmp/checkout-down
```

## 2. Readiness failure without restart

Inject the readiness failure:

```bash
kubectl -n readiness-lab exec \
  deployment/readiness-demo \
  -- touch /tmp/not-ready
```

Wait for the unready condition:

```bash
kubectl -n readiness-lab wait \
  --for=condition=Ready=false \
  pod -l app=readiness-demo \
  --timeout=45s
```

Inspect the Pod and EndpointSlices:

```bash
kubectl -n readiness-lab get pods

kubectl -n readiness-lab get endpointslices \
  -l kubernetes.io/service-name=readiness-demo \
  -o yaml
```

Restore readiness:

```bash
kubectl -n readiness-lab exec \
  deployment/readiness-demo \
  -- rm /tmp/not-ready
```

Wait for recovery:

```bash
kubectl -n readiness-lab wait \
  --for=condition=Ready \
  pod -l app=readiness-demo \
  --timeout=45s
```

## 3. Failed rolling update and rollback

Introduce a Deployment revision that never becomes ready:

```bash
kubectl -n readiness-lab set env \
  deployment/readiness-demo \
  READY_ON_START=false
```

Observe the expected rollout failure:

```bash
kubectl -n readiness-lab rollout status \
  deployment/readiness-demo \
  --timeout=130s
```

Inspect controller conditions and replicas:

```bash
kubectl -n readiness-lab describe \
  deployment readiness-demo

kubectl -n readiness-lab get pods
```

The previous healthy Pod should remain available,
assuming the lab has sufficient resources.

Rollback:

```bash
kubectl -n readiness-lab rollout undo \
  deployment/readiness-demo
```

Verify the restored Deployment state:

```bash
kubectl -n readiness-lab get deployment readiness-demo \
  -o jsonpath='{range .status.conditions[*]}{.type}{" = "}{.status}{" | "}{.reason}{"\n"}{end}'

kubectl -n readiness-lab get pods
```

Important: rollout undo does not update the
last-applied-configuration annotation used by kubectl apply.

The controller may also require time to reconcile
the restored revision before rollout status reports success.

## 4. Liveness failure and container restart

Record the initial restart count:

```bash
kubectl -n readiness-lab get pods
```

Inject the simulated liveness failure:

```bash
kubectl -n readiness-lab exec \
  deployment/readiness-demo \
  -- touch /tmp/not-live
```

Observe the Pod:

```bash
kubectl -n readiness-lab get pods -w
```

Stop watching with Ctrl+C after recovery.

Inspect kubelet events:

```bash
kubectl -n readiness-lab describe pods \
  -l app=readiness-demo
```

The expected behavior is a container restart after
repeated liveness failures.

The failure flag disappears when the container's
writable filesystem is recreated.

## Final verification

After recovery:

```bash
./scripts/verify.sh
```
