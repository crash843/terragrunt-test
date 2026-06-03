# implicit — two Spacelift stacks chained with output reference

Demonstrates the per-workspace pattern from
`fatmouse/docs/cross-workspace-dependencies.md`:

- two **separate Spacelift stacks**, one per area,
- each one an implicit Terragrunt stack with an intra-stack DAG,
- `apps` consumes `networking`'s output through a
  `spacelift_stack_dependency_reference`,
- and runs automatically after `networking` applies via the same dependency.

```
new/implicit/
├── networking/                  Spacelift stack #1 (use run-all on)
│   ├── root.hcl
│   ├── vpc/                     unit, outputs vpc_id
│   └── routing/                 unit, depends on vpc (intra-stack)
└── apps/                        Spacelift stack #2 (depends on networking)
    ├── root.hcl
    ├── db/                      unit, reads TF_VAR_vpc_id from Spacelift
    └── app/                     unit, depends on db (intra-stack)
```

Two DAGs:

- inside `networking`: `vpc -> routing` (resolved by Terragrunt's `run --all`).
- between Spacelift stacks: `networking -> apps` (resolved by Spacelift's
  stack dependency).

## Spacelift setup

Two stacks plus a dependency with an output reference.

| Spacelift stack | Project root | Use run-all | Manage state |
|---|---|---|---|
| `impl-networking` | `new/implicit/networking` | on | on (no stack file here, fine) |
| `impl-apps`       | `new/implicit/apps`       | on | on |

### Dependency + output reference

```hcl
resource "spacelift_stack" "networking" {
  name         = "impl-networking"
  repository   = "<your-repo>"
  branch       = "main"
  project_root = "new/implicit/networking"
  terragrunt   = { use_run_all = true }
}

resource "spacelift_stack" "apps" {
  name         = "impl-apps"
  repository   = "<your-repo>"
  branch       = "main"
  project_root = "new/implicit/apps"
  terragrunt   = { use_run_all = true }
}

resource "spacelift_stack_dependency" "apps_after_networking" {
  stack_id            = spacelift_stack.apps.id
  depends_on_stack_id = spacelift_stack.networking.id
}

resource "spacelift_stack_dependency_reference" "vpc_id_to_apps" {
  stack_dependency_id = spacelift_stack_dependency.apps_after_networking.id
  input_name          = "TF_VAR_vpc_id"   # delivered as env var to apps run
  output_name         = "vpc_id"          # from networking's vpc unit
}
```

## What to look for

- Trigger `impl-networking` apply. On success, `impl-apps` queues automatically.
- `impl-apps` starts with `TF_VAR_vpc_id` already set in the runner env; `db`
  and `app` units both read it via `var.vpc_id` without any extra wiring.
- Inside each Spacelift stack, run-all walks the intra-stack DAG: `vpc -> routing`
  on the networking side, `db -> app` on the apps side.
- `vpc_id` is `terraform_data.vpc.id`, which is replaced every apply via
  `triggers_replace = [timestamp()]`. So every networking apply produces a new
  `vpc_id` and re-triggers `impl-apps`.

## What this exercises from the design doc

- **Cross-stack output reference, env-var delivery** (Spacelift's
  `spacelift_stack_dependency_reference`).
- **Auto-trigger downstream on upstream apply**
  (`spacelift_stack_dependency` — Scalr's `RunTrigger` equivalent).
- **Intra-stack Terragrunt DAG resolution under run-all** (works the same on
  both platforms).
- **Per-stack isolation** — `networking` and `apps` have independent state,
  history, approvals.
