# Architecture

## Blue/Green repave rotation

State (which environment is active) lives in a single DynamoDB item, not in Terraform state itself — this keeps the "which one is live" question fast to read/write and independent of any one Terraform run.

Table: `blue-green-repave-state` (created once via `terraform/bootstrap`)

| pk           | active_env | last_repaved_at        |
|--------------|-----------|--------------------------|
| `env-state`  | `blue`    | 2026-09-11T06:00:00Z    |

Daily workflow logic:

```
inactive_env = (active_env == blue) ? green : blue

1. terraform destroy  -> environments/<inactive_env>
2. terraform apply    -> environments/<inactive_env>
3. run smoke checks against the freshly-applied env
4. if healthy:
     - flip routing to point at <inactive_env>
     - update DynamoDB: active_env = <inactive_env>, last_repaved_at = now
   if unhealthy:
     - abort, leave routing untouched, alert
```

The environment currently serving traffic is never the one being destroyed — only the idle one gets repaved, then promoted.

## Why traffic switching differs by pattern

**Container / LB-fronted workloads:** straightforward. Swap the target group (or weight) behind the load balancer once the new environment passes its health check. No special handling needed — the LB absorbs the cutover.

**Non-LB event-driven paths (e.g. S3 notification → Lambda, or EventBridge → Lambda):** these don't have a load balancer to hide the cutover behind. If S3 (or EventBridge) invokes the Lambda directly and that Lambda's underlying infra is mid-repave, invocations during the switch window can be dropped or fail with no automatic retry path that fits our rotation logic.

**Fix: put SQS in between.**

```
S3 / EventBridge -> SQS (buffer, with DLQ) -> Lambda (polls SQS)
```

SQS decouples the producer (S3/EventBridge) from the consumer (Lambda):

- Messages queue up safely even if nothing is consuming them for a few minutes during a repave.
- The event source mapping between SQS and Lambda can be **disabled** right before repaving the environment that owns the Lambda, and **re-enabled** once the new environment is up — no events are lost, they just wait in the queue.
- A DLQ catches anything that repeatedly fails processing, independent of the repave cycle.

This is handled in `terraform/modules/notification-pipeline`, which exposes an `event_source_mapping_enabled` variable the workflow flips during repave.

## Open design question (flagged, not yet resolved)

For **non-container, non-LB-fronted resources** in general (not just the S3/SQS/Lambda case) — anything exposed some other way that still needs a clean "which copy is authoritative right now" answer — the active/inactive flag in DynamoDB is the source of truth, and each resource type needs its own small adapter that reads that flag and reacts accordingly (enable/disable, update a Route53 weight, swap an alias, etc.). The notification-pipeline module is the first such adapter; treat it as the template for others.
