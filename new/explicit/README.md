# explicit (native) — multi-env stamping demo

Demonstrates the canonical native-stacks win: one shared catalog, N envs, one
stack file per env that picks values. The catalog lives at the **repo root**
so a single driver can cover all envs.

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

## Topology

Two pieces:

- **One driver** — either a Spacelift stack OR a Scalr workspace — runs
  `terragrunt run --all` over `new/explicit/`, auto-generating both envs'
  `.terragrunt-stack/` trees and walking all four units.
- **Four state-only Scalr workspaces** hold the unit states
  (`explicit-{dev,prod}-{vpc,app}`).

The state target is declared in `root.hcl`, independent of who drives. Pick
either driver below.

## Driver: Spacelift — pick ONE of these

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

## Driver: Scalr (single workspace running run-all)

One Scalr workspace that drives the run, plus the same four state-only
workspaces that hold per-unit state.

| Scalr workspace | `working_directory` | `terragrunt_version` | `tg_use_run_all` | `remote_backend` (managed state) | Execution mode |
|---|---|---|---|---|---|
| `explicit-runner`  | `new/explicit`     | 0.78+ | **on**  | **off** (required — Scalr forbids the combo of run-all + managed state) | remote |
| `explicit-dev-vpc`  | (none)            | — | off  | off  | local (state-only) |
| `explicit-dev-app`  | (none)            | — | off  | off  | local (state-only) |
| `explicit-prod-vpc` | (none)            | — | off  | off  | local (state-only) |
| `explicit-prod-app` | (none)            | — | off  | off  | local (state-only) |

The driver doesn't store its own Terraform state — `terragrunt run --all` only
orchestrates; each unit independently initialises a backend that points at its
own state-only Scalr workspace via the locals in `root.hcl`.

### Env var on the driver workspace

The agent needs the Scalr API token to authenticate state writes to the four
state-only workspaces:

```
TF_TOKEN_<scalr-host-dots-as-underscores> = <Scalr API token>     (sensitive)
```

Same env var name as on the Spacelift side. Account-scoped token with state
read/write on the four state workspaces is enough.

### Why the driver has `remote_backend = off`

Scalr's API rejects `tg_use_run_all = true` together with `remote_backend = true`
(see `taco/app/workspace/apis/workspaces.py:3648-3652`). The constraint exists
because a single Scalr workspace can hold only one state slot, but run-all has N
unit states. Turning `remote_backend` off says "Scalr doesn't manage state for
this workspace" — and `root.hcl`'s `remote_state` block routes each unit's state
to its own state-only workspace instead.

## What to look for

- One catalog change reaches every env on the next run.
- `envs/{dev,prod}/.terragrunt-stack/{vpc,app}/` is generated at runtime; never
  commit it.
- In option A: a single Spacelift run lists four units (`envs/dev/.terragrunt-stack/vpc`,
  `envs/dev/.terragrunt-stack/app`, `envs/prod/.terragrunt-stack/vpc`,
  `envs/prod/.terragrunt-stack/app`). In option B: two units per run.

## State storage on Scalr

`root.hcl` declares Scalr's TFE-compatible backend with one Scalr workspace per
generated unit, addressed by name. Four state files live in four Scalr
workspaces. Same setup regardless of whether Spacelift or Scalr drives the run.

### One-time setup in Scalr

1. **Create four state-only workspaces** with execution mode **local** (Scalr
   stores state, doesn't run):
   - `explicit-dev-vpc`
   - `explicit-dev-app`
   - `explicit-prod-vpc`
   - `explicit-prod-app`

2. **If Scalr is the driver:** create the driver workspace
   (`explicit-runner`, working_directory `new/explicit`, `tg_use_run_all = on`,
   `remote_backend = off`).

3. **Generate an API token** with state read/write on the four state
   workspaces. Account-level token is simplest.

4. **Edit `root.hcl`**: replace `<your-scalr-host>` and `<your-scalr-account>`.

### Env var on the driver

Set on whichever driver you're using (Spacelift stack OR Scalr workspace):

```
TF_TOKEN_<scalr-host-dots-as-underscores> = <Scalr API token>     (sensitive)
```

For hostname `acme.scalr.io` the env var is `TF_TOKEN_acme_scalr_io`. Terraform
1.2+ reads this automatically when initialising the `remote` backend against
that hostname.

Spacelift's Manage state stays off; the runner uses our backend declaration,
not Spacelift's.

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
