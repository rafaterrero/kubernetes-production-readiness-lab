# Lab Architecture

The lab runs in a disposable, single-node Kind cluster.

```text
Host (Docker)
    |
    +-- Kind control-plane
          |
          +-- Namespace: readiness-lab
                |
                +-- Deployment: readiness-demo
                |     |
                |     +-- Python HTTP server
                |     +-- Startup probe
                |     +-- Readiness probe
                |     +-- Liveness probe
                |
                +-- Service: readiness-demo
                |
                +-- EndpointSlice
```

## Application endpoints

| Endpoint | Purpose |
|---|---|
| /startup | Reports successful startup |
| /live | Simulates process liveness |
| /ready | Controls traffic eligibility |
| /checkout | Simulates business functionality |

Failure flags are created under /tmp inside the container.

## Rolling update strategy

The Deployment uses:

- replicas: 1
- maxSurge: 1
- maxUnavailable: 0
- minReadySeconds: 5
- progressDeadlineSeconds: 90

This allows an additional Pod to be created while
the previous available replica remains running,
provided sufficient cluster resources are available.

These settings do not guarantee zero downtime.
