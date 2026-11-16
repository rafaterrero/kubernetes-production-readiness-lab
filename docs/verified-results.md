# Verified Lab Results

Date: 2026-11-16

Environment:

- Ubuntu 24.04
- Docker 29.10.0
- Kind 0.33.0
- Kubernetes server 1.37.0
- kubectl 1.37.2

These findings are based on experiments executed
in a disposable local Kind cluster.

They are not production workload benchmarks.

## Experiment 1: Business functionality failure

Observed:

- /ready returned HTTP 200.
- /checkout returned HTTP 503.
- Deployment remained 1/1 READY.
- Container restart count remained 0.

Conclusion:

Successful readiness did not guarantee that the
simulated business operation was functioning.

## Experiment 2: Readiness failure

Observed:

- Pod became 0/1 Ready.
- Pod remained Running.
- Container restart count remained 0.
- EndpointSlice reported ready=false.
- EndpointSlice reported serving=false.

After removal of the failure flag, readiness recovered.

Conclusion:

Readiness failure removed the Pod from normal Service
traffic eligibility without restarting the container.

## Experiment 3: Failed rollout

Observed:

- New Pod: Running, 0/1 Ready.
- Previous Pod: Running, 1/1 Ready.
- Deployment remained Available=True.
- Deployment reported ProgressDeadlineExceeded.
- EndpointSlice selected the old Pod as ready.

The rollback command restored the previous template.

Immediately after rollback, rollout status still
reported the previous progress deadline failure.

Subsequent inspection confirmed:

- READY_ON_START=true
- Observed generation: 3/3
- Progressing=True
- Reason=NewReplicaSetAvailable
- One updated and available replica
- Failed ReplicaSet scaled to zero

Conclusion:

Rollback initiation and verified recovery are
separate operational checks.

## Experiment 4: Liveness failure

Observed:

- Three HTTP 503 liveness failures.
- Kubelet emitted a container Killing event.
- Container restart count increased from 0 to 1.
- Previous container exit code was 137.
- Pod recovered to Running and Ready.

Exit code 137 alone does not establish an
out-of-memory condition. Kubelet events provided
the reason for the restart in this experiment.

## Final service verification

The Deployment successfully rolled out.

Requests through the Kubernetes Service returned:

- /ready: HTTP 200
- /checkout: HTTP 200

Final recovery evidence is stored in:

`../evidence/final-recovery.txt`
