#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="readiness-lab"
DEPLOYMENT="readiness-demo"
EXPECTED_CONTEXT="kind-readiness-lab"

CURRENT_CONTEXT="$(kubectl config current-context)"

if [[ "$CURRENT_CONTEXT" != "$EXPECTED_CONTEXT" ]]; then
    echo "ERROR: Unexpected Kubernetes context: $CURRENT_CONTEXT"
    echo "Expected: $EXPECTED_CONTEXT"
    exit 1
fi

echo "=== Kubernetes Context ==="
echo "$CURRENT_CONTEXT"

echo
echo "=== Rollout Status ==="
kubectl -n "$NAMESPACE" rollout status \
    "deployment/$DEPLOYMENT" \
    --timeout=60s

echo
echo "=== Deployment and Pods ==="
kubectl -n "$NAMESPACE" get deployments,pods

echo
echo "=== Application Service Check ==="

kubectl -n "$NAMESPACE" exec -i \
    "deployment/$DEPLOYMENT" -- python - <<'PY'
import sys
from urllib.request import urlopen
from urllib.error import HTTPError

base = "http://readiness-demo.readiness-lab.svc.cluster.local"

success = True

for path in ("/ready", "/checkout"):
    try:
        with urlopen(base + path, timeout=5) as response:
            status = response.status
    except HTTPError as exc:
        status = exc.code
    except Exception as exc:
        print(f"{path}: ERROR - {exc}")
        success = False
        continue

    print(f"{path}: HTTP {status}")

    if status != 200:
        success = False

sys.exit(0 if success else 1)
PY

echo
echo "=== EndpointSlices ==="
kubectl -n "$NAMESPACE" get endpointslices \
    -l kubernetes.io/service-name=readiness-demo \
    -o jsonpath='{range .items[*].endpoints[*]}{.targetRef.name}{" ready="}{.conditions.ready}{"\n"}{end}'

echo
READY_ENDPOINTS="$(kubectl -n "$NAMESPACE" get endpointslices -l "kubernetes.io/service-name=$DEPLOYMENT" -o jsonpath='{range .items[*].endpoints[*]}{.conditions.ready}{"\n"}{end}')"

if [[ "$READY_ENDPOINTS" != "true" ]]; then
    echo "ERROR: Expected exactly one ready endpoint." >&2
    echo "Observed: ${READY_ENDPOINTS:-none}" >&2
    exit 1
fi

echo "Healthy application verification completed."
