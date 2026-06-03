# explicit (native) — multi-env stamping demo

Demonstrates the canonical native-stacks win: one catalog template, N envs, one
stack file per env that picks values.

```
new/explicit/
├── root.hcl                       common config, included by every unit
├── catalog/units/                 templates, OUTSIDE any env's project root
│   ├── vpc/{terragrunt.hcl,main.tf}
│   └── app/{terragrunt.hcl,main.tf}    depends on vpc
└── envs/
    ├── dev/terragrunt.stack.hcl   stamps vpc + app with dev values
    └── prod/terragrunt.stack.hcl  stamps vpc + app with prod values
```

The catalog lives outside `envs/dev/` and `envs/prod/`, so `run --all` from
either project root won't discover the templates as standalone units (the same
trap caught in `../../native-stacks/` earlier).

## Spacelift setup

Two stacks, one per env:

| Spacelift stack | Project root | Use run-all | Manage state |
|---|---|---|---|
| `explicit-dev`  | `new/explicit/envs/dev`  | on | off |
| `explicit-prod` | `new/explicit/envs/prod` | on | off |

Both stacks reference the **same** `catalog/units/{vpc,app}`. Editing
`catalog/units/vpc/main.tf` affects every env on the next run.

### As Spacelift TF (optional)

```hcl
resource "spacelift_stack" "dev" {
  name             = "explicit-dev"
  repository       = "<your-repo>"
  branch           = "main"
  project_root     = "new/explicit/envs/dev"
  terragrunt       = { use_run_all = true }
  manage_state     = false
}

resource "spacelift_stack" "prod" {
  name             = "explicit-prod"
  repository       = "<your-repo>"
  branch           = "main"
  project_root     = "new/explicit/envs/prod"
  terragrunt       = { use_run_all = true }
  manage_state     = false
}
```

### Optional dev → prod promotion

Wire prod to run after dev with a stack dependency:

```hcl
resource "spacelift_stack_dependency" "prod_after_dev" {
  stack_id            = spacelift_stack.prod.id
  depends_on_stack_id = spacelift_stack.dev.id
}
```

A successful dev apply will queue a prod run (prod still needs its own
approval).

## What to look for

- One catalog change reaches both envs on the next run.
- `dev` and `prod` have independent state, independent triggers, independent
  approvals.
- `envs/{dev,prod}/.terragrunt-stack/{vpc,app}/` exists at runtime and is
  regenerated each run; never commit it.

## State

Manage state must be off (Spacelift can't inject a backend into generated unit
files). For a fixture this is fine — local backend in an ephemeral worker
container; state is lost between runs, every plan shows a diff because of the
`triggers_replace = [timestamp()]` on each `terraform_data` resource. For real
infra, add an `s3` `remote_state` block in `root.hcl` keyed by
`${path_relative_to_include()}/terraform.tfstate`.
