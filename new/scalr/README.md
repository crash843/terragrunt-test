# scalr — single Scalr workspace driving a native stack with run-all

A focused, Scalr-only version of the explicit demo. One Scalr workspace runs
`terragrunt run --all` over a native stack; state goes to two state-only Scalr
workspaces via the TFE-compatible remote backend.

```
/catalog-multi-env/units/         shared catalog at repo root
├── vpc/{terragrunt.hcl, main.tf}
└── app/{terragrunt.hcl, main.tf}     depends on vpc

new/scalr/
├── root.hcl                       Scalr remote backend, one workspace per unit
└── terragrunt.stack.hcl           two units (vpc, app), stamped from catalog
```

## Topology

| Scalr workspace | `working_directory` | `terragrunt_version` | `tg_use_run_all` | `remote_backend` (managed state) | Execution mode |
|---|---|---|---|---|---|
| `scalr-runner` (driver) | `new/scalr` | 0.78+ | **on** | **off** (required — run-all + managed state is rejected) | remote |
| `scalr-vpc` (state-only)  | (none) | — | off | off | local |
| `scalr-app` (state-only)  | (none) | — | off | off | local |

The driver workspace doesn't store state. Each generated unit initialises a
remote backend pointing at its own state-only workspace via the locals in
`root.hcl` (`scalr-${basename(get_terragrunt_dir())}` → `scalr-vpc`, `scalr-app`).

## One-time setup

1. **Driver workspace** in Scalr:
   - `working_directory = new/scalr`
   - `terragrunt_version >= 0.78`
   - `tg_use_run_all = true`
   - `remote_backend = false`
   - VCS source: this repo, branch `main`.

2. **Two state-only workspaces** in the same Scalr environment, execution mode
   **local** (Scalr only stores state, doesn't run):
   - `scalr-vpc`
   - `scalr-app`

3. **Edit `root.hcl`**: replace `<your-scalr-environment-name>` with the Scalr
   environment that holds the state-only workspaces. The hostname is already
   set to the test environment
   (`mainiacp.ik-test-cv-error.testenv.scalr.dev`); change it if you move to a
   real environment.

4. **Generate a Scalr API token** with state read/write on `scalr-vpc` and
   `scalr-app`.

5. **Set the env var on the driver workspace** (marked sensitive):

   ```
   TF_TOKEN_mainiacp_ik-test-cv-error_testenv_scalr_dev = <token>
   ```

   Terraform 1.2+ reads this when initialising the `remote` backend against
   that hostname. Note the period-to-underscore transformation; hyphens stay
   as-is.

## What happens on a run

1. Driver workspace clones the repo, `cd`s into `new/scalr/`, runs
   `terragrunt run --all plan`.
2. Terragrunt finds `terragrunt.stack.hcl`, auto-generates
   `.terragrunt-stack/{vpc,app}/` from the shared catalog.
3. Each generated unit's `terraform init` writes a `backend.tf` from the
   `remote_state` block, pointing at its own state-only Scalr workspace.
4. `vpc` plans first (no dependencies), then `app` (depends on vpc, reads its
   output via the `dependency` block — which works because the API token
   authenticates state reads too).
5. After approval, run-all applies. State writes land in `scalr-vpc` and
   `scalr-app`. Outputs visible in those workspaces' UI.

## What it doesn't demo

- Per-env stamping (single stack, single env). See [../explicit/](../explicit/)
  for two envs (dev/prod) stamped from the same catalog.
- Cross-Scalr-workspace `RunTrigger` chaining (no upstream/downstream here).
- Spacelift drivers — that path is documented in
  [../explicit/README.md](../explicit/README.md).

## Why `remote_backend` must be off on the driver

Scalr's workspace API rejects the combination
`tg_use_run_all = true` with `remote_backend = true` at
[`taco/app/workspace/apis/workspaces.py:3648-3652`](https://github.com/Scalr/fatmouse/blob/master/taco/app/workspace/apis/workspaces.py#L3648).
A single workspace's managed state slot can hold only one state file; run-all
produces N. Turning `remote_backend` off says "Scalr doesn't manage state for
this workspace," and `root.hcl` then routes each unit's state to its own
state-only workspace.
