# explicit (native) — multi-env stamping demo

Demonstrates the canonical native-stacks win: one shared catalog, N envs, one
stack file per env that picks values. The catalog lives at the **repo root**
so a single Spacelift stack can cover all envs.

```
/catalog-multi-env/units/         shared catalog at repo root
├── vpc/{terragrunt.hcl, main.tf}
└── app/{terragrunt.hcl, main.tf}     depends on vpc

new/explicit/
├── root.hcl                       common config, included by every unit
└── envs/
    ├── dev/terragrunt.stack.hcl   stamps vpc + app with dev values
    └── prod/terragrunt.stack.hcl  stamps vpc + app with prod values
```

## Spacelift setup — pick ONE of these

### Option A: one stack, both envs at once

Single Spacelift stack walks both `envs/dev` and `envs/prod`, auto-generates
both `.terragrunt-stack/` trees, runs all four units.

| Spacelift stack | Project root | Use run-all | Manage state |
|---|---|---|---|
| `explicit-all` | `new/explicit` | on | off |

Catalog at `/catalog-multi-env/` is outside `new/explicit/` — run-all walks
only the env stack files, never the catalog templates.

Trade-off: one trigger fires both envs, one approval gates both. A failure in
dev fails the whole run before prod applies. Use only when both envs really
should move together.

### Option B: one stack per env (recommended for real lifecycles)

| Spacelift stack | Project root | Use run-all | Manage state |
|---|---|---|---|
| `explicit-dev`  | `new/explicit/envs/dev`  | on | off |
| `explicit-prod` | `new/explicit/envs/prod` | on | off |

Independent triggers, independent approvals, independent state. Optionally
chain dev → prod with `spacelift_stack_dependency`.

### As Spacelift TF (option A)

```hcl
resource "spacelift_stack" "all" {
  name             = "explicit-all"
  repository       = "<your-repo>"
  branch           = "main"
  project_root     = "new/explicit"
  terragrunt       = { use_run_all = true }
  manage_state     = false
}
```

### As Spacelift TF (option B)

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

resource "spacelift_stack_dependency" "prod_after_dev" {
  stack_id            = spacelift_stack.prod.id
  depends_on_stack_id = spacelift_stack.dev.id
}
```

## What to look for

- One catalog change reaches every env on the next run.
- `envs/{dev,prod}/.terragrunt-stack/{vpc,app}/` is generated at runtime; never
  commit it.
- In option A: a single Spacelift run lists four units (`envs/dev/.terragrunt-stack/vpc`,
  `envs/dev/.terragrunt-stack/app`, `envs/prod/.terragrunt-stack/vpc`,
  `envs/prod/.terragrunt-stack/app`). In option B: two units per run.

## State

Manage state must be off (Spacelift can't inject a backend into generated unit
files). For this fixture this is fine — local backend in an ephemeral worker;
state is lost between runs, every plan shows a diff because of
`triggers_replace = [timestamp()]`. For real infra, add an `s3` `remote_state`
block in `root.hcl` keyed by `${path_relative_to_include()}/terraform.tfstate`.
