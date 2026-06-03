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

## State storage on Scalr

Spacelift "Manage state" stays off. `root.hcl` declares Scalr's TFE-compatible
backend with one Scalr workspace per generated unit, addressed by name. Four
state files live in four Scalr workspaces.

### One-time setup in Scalr

1. **Create four workspaces** in your Scalr account. Set execution mode to
   **local** so Scalr only stores state, not runs:
   - `explicit-dev-vpc`
   - `explicit-dev-app`
   - `explicit-prod-vpc`
   - `explicit-prod-app`

2. **Generate an API token** with state read/write on those workspaces.
   Account-level token is simplest.

3. **Edit `root.hcl`**: replace `<your-scalr-host>` (e.g. `acme.scalr.io`) and
   `<your-scalr-account>` (your Scalr account name).

### One-time setup in Spacelift

Set an env var on the `explicit-all` stack (or each per-env stack):

```
TF_TOKEN_<scalr-host-dots-as-underscores> = <Scalr API token>
```

For hostname `acme.scalr.io` the env var is `TF_TOKEN_acme_scalr_io`. Terraform
1.2+ reads this automatically when initialising the `remote` backend against
`acme.scalr.io`. Mark it sensitive.

Manage state stays off; the runner uses our backend declaration, not
Spacelift's.

### What changes vs the local-backend fixture

| Aspect | Local backend (default) | Scalr backend |
|---|---|---|
| State persistence between runs | none — worker is ephemeral | yes — stored in Scalr |
| `terraform plan` second run | "create" again (state lost) | "no changes" except `triggers_replace` |
| Cross-unit `dependency` reads | uses `mock_outputs` | reads real outputs from Scalr |
| Outputs visible in Scalr UI | n/a | yes, per workspace |
| Roll back | not possible | via Scalr state version history |

### Cross-unit dependency reads (app → vpc)

With Scalr as backend, the `dependency "vpc" { config_path = "../vpc" }` block
in the app unit's generated terragrunt.hcl initialises the vpc directory's
backend (Scalr's `explicit-<env>-vpc` workspace) and reads its outputs. No
extra ACL needed — the API token authenticates the read. If you wanted
cross-workspace reads in user-written Terraform via `data
"terraform_remote_state"`, you'd add the consumer to the source workspace's
Remote State Sharing list (Scalr's `RemoteStateConsumer` ACL).
