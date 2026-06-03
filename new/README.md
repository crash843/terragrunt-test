# new — Spacelift demo fixtures

Two small demos that exercise the flows discussed in
`fatmouse/docs/cross-workspace-dependencies.md`. Provider-free
(`terraform_data` only, no cloud creds), every apply shows a diff
(`triggers_replace = [timestamp()]`), runs on Spacelift with the standard
Terragrunt vendor.

| Demo | What it shows |
|---|---|
| [explicit/](explicit/) | Native stacks: shared catalog at repo root, two envs (dev/prod) stamped from it. Set up as **one Spacelift stack covering both envs** (project_root `new/explicit`), or **one stack per env** (project_root `new/explicit/envs/<env>`). |
| [implicit/](implicit/) | Two Spacelift stacks chained: `networking` outputs `vpc_id`, `apps` receives it as `TF_VAR_vpc_id` via `spacelift_stack_dependency_reference`, runs automatically after each `networking` apply. Demonstrates per-workspace cross-stack output delivery. |

Each subfolder has its own README with the Spacelift configuration.

The shared catalog used by the explicit demo lives at the repo root in
`/catalog-multi-env/units/{vpc,app}`. Editing those templates affects every env
on the next run.

## Spacelift settings at a glance

| Demo stack | Project root | Use run-all | Manage state | Depends on |
|---|---|---|---|---|
| `explicit-all`    | `new/explicit`            | on | off (native stack) | — (runs both envs in one go) |
| `explicit-dev`    | `new/explicit/envs/dev`   | on | off (native stack) | — |
| `explicit-prod`   | `new/explicit/envs/prod`  | on | off (native stack) | optionally `explicit-dev` |
| `impl-networking` | `new/implicit/networking` | on | on (no stack file) | — |
| `impl-apps`       | `new/implicit/apps`       | on | on (no stack file) | `impl-networking` |

Pick `explicit-all` to fire both envs from a single trigger, or
`explicit-dev` + `explicit-prod` for independent lifecycles.

## Scalr equivalent for the explicit demo

The explicit demo also runs from a single Scalr workspace. The state target is
declared in `root.hcl` and is the same regardless of who drives.

| Scalr workspace | `working_directory` | `tg_use_run_all` | `remote_backend` (managed state) | Execution mode |
|---|---|---|---|---|
| `explicit-runner`  | `new/explicit` | on | off (required) | remote |
| `explicit-dev-vpc` / `explicit-dev-app` / `explicit-prod-vpc` / `explicit-prod-app` | (none) | off | off | local (state-only) |

The driver workspace orchestrates; each unit independently writes to its own
state-only workspace via `root.hcl`. See [explicit/README.md](explicit/) for
details.

Native-stacks demos must have **Manage state off** — Spacelift can't inject a
backend into generated unit files. Implicit demos keep **Manage state on**
because each project root is plain Terragrunt that Spacelift's backend
injection handles cleanly.
