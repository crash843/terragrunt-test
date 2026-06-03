# local — 7-unit DAG to explore Terragrunt targeting locally

Two fixtures with the **same dependency graph**, one written as implicit
directories, one declared as a native stack file. Provider-free
(`terraform_data` only), every apply forces replacement
(`triggers_replace = [timestamp()]`), so each plan/apply shows visible work.
No backend declared — Terragrunt uses local state per unit.

Runs on your laptop with `terragrunt >= 0.78`.

## The graph

7 units, 3 roots, fan-out, fan-in (4 parents), and a chain at the end.

```
                   network        iam        dns
                    │ │ │          │          │
            ┌───────┘ │ └────┐     │          │
            │         │      │     │          │
            ▼         ▼      │     │          │
        data_db   data_cache │     │          │
            │         │      │     │          │
            └────┬────┘      │     │          │
                 │           │     │          │
                 └─────┬─────┴─────┘          │
                       │                       │
                       ▼                       │
                    compute                    │
                       │                       │
                       └──────────┬────────────┘
                                  │
                                  ▼
                                edge
```

| Unit | Depends on | Type |
|---|---|---|
| `network`    | — | root |
| `iam`        | — | root |
| `dns`        | — | root |
| `data_db`    | network | linear |
| `data_cache` | network | linear |
| `compute`    | network, iam, data_db, data_cache | fan-in (4 parents) |
| `edge`       | compute, dns | terminal |

Topological order: `{network, iam, dns}` → `{data_db, data_cache}` → `compute`
→ `edge`. The three roots run in parallel; `data_db` and `data_cache` run in
parallel; `compute` waits for four parents; `edge` waits for `compute` and `dns`.

## Layout

```
new/local/
├── implicit/                       hand-written, units in repo
│   ├── root.hcl
│   ├── network/{terragrunt.hcl, main.tf}
│   ├── iam/{terragrunt.hcl, main.tf}
│   ├── dns/{terragrunt.hcl, main.tf}
│   ├── data_db/{terragrunt.hcl, main.tf}
│   ├── data_cache/{terragrunt.hcl, main.tf}
│   ├── compute/{terragrunt.hcl, main.tf}
│   └── edge/{terragrunt.hcl, main.tf}
│
├── explicit/                       native stack
│   ├── root.hcl
│   └── terragrunt.stack.hcl        7 unit blocks, sources from ../catalog
│
└── catalog/units/                  outside explicit/, not discovered by run-all
    ├── network/{terragrunt.hcl, main.tf}    template, uses values.cidr
    ├── iam/{terragrunt.hcl, main.tf}        template, uses values.service_name
    ├── dns/{terragrunt.hcl, main.tf}        template, uses values.zone
    ├── data_db/{terragrunt.hcl, main.tf}    deps network
    ├── data_cache/{terragrunt.hcl, main.tf} deps network
    ├── compute/{terragrunt.hcl, main.tf}    fan-in
    └── edge/{terragrunt.hcl, main.tf}       terminal
```

The same DAG, the same units, the same outputs — the only difference is **how
the unit code arrives on disk**.

## Quick start

```bash
cd new/local/implicit       # or new/local/explicit
terragrunt run --all plan
terragrunt run --all apply
```

For the explicit fixture, `run --all` auto-generates `.terragrunt-stack/`
before walking the units (Terragrunt 0.78+). If you want to see it explicitly:

```bash
cd new/local/explicit
terragrunt stack generate    # writes .terragrunt-stack/{network,iam,dns,data_db,data_cache,compute,edge}/
terragrunt stack run plan
```

## Scenarios to compare

Each scenario lists what runs, what doesn't, and the visible side effect on
units that stay out of the queue. Run them in order; state from one carries
into the next.

Paths below use the implicit form (`data_db` etc.). For the explicit fixture
prefix with `.terragrunt-stack/` (e.g. `.terragrunt-stack/data_db`).

### Scenario 0 — first plan and apply (everything)

```bash
terragrunt run --all plan
terragrunt run --all apply
```

Plan shows 7 units, each "create" (the `terraform_data` resource). Apply
creates them in topological order. Three roots run in parallel; `compute`
waits for four parents; `edge` waits for `compute` and `dns`.

### Scenario 1 — plan again, no targeting

```bash
terragrunt run --all plan
```

`triggers_replace = [timestamp()]` makes every unit show a planned replacement.
This is the "everything diffs every run" mode the fixture uses; in real infra
you'd see no-op plans here.

### Scenario 2 — target `compute` with default expansion

```bash
terragrunt run --all plan --queue-include-dir=compute
```

Queue: `[network, iam, data_db, data_cache, compute]` — the target plus its
**four immediate parents**. `dns` and `edge` are not touched. Expansion is one
level up, not transitive (so this happens to cover the whole upstream here
only because the parents are themselves roots).

To inspect what Terragrunt expanded:

```bash
terragrunt run --all plan --queue-include-dir=compute --log-level debug 2>&1 | grep -E "Discovered|Running"
```

### Scenario 3 — target `compute` strictly

```bash
terragrunt run --all plan --queue-include-dir=compute --queue-strict-include
```

Queue: `[compute]` only. Parents are read for their state (via the
`dependency` blocks) but not re-planned. `dns`, `edge`, `network`, `iam`,
`data_db`, `data_cache` are not touched.

### Scenario 4 — apply just `data_db` strictly, then plan downstream

```bash
terragrunt run --all apply --queue-include-dir=data_db --queue-strict-include
terragrunt run --all plan --queue-include-dir=compute --queue-strict-include
terragrunt run --all plan --queue-include-dir=edge   --queue-strict-include
```

The first command re-applies `data_db`, generating a new `db_endpoint`. The
two follow-up plans show **drift**: `compute` reads the new `db_endpoint`
(through its `dependency` block) while its own stored state still has the old
one — Terraform shows a replacement. `edge` shows a replacement too, because
its `api_url` input is derived from `compute`'s state.

This visualises the "logical drift" we talked about: data_db moved, compute
and edge weren't re-applied, but their next plan shows they're stale.

### Scenario 5 — target a downstream alone (no upstream expansion)

```bash
terragrunt run --all plan --queue-include-dir=edge --queue-strict-include
```

Queue: `[edge]`. Reads `compute` and `dns` state for the dependency blocks but
doesn't re-plan them.

### Scenario 6 — target a downstream WITH upstream expansion (default)

```bash
terragrunt run --all plan --queue-include-dir=edge
```

Queue: `[edge, compute, dns]` — **only edge plus its *immediate* parents**.
Default `--queue-include-dir` expansion is one level upstream, NOT transitive.
`network`, `iam`, `data_db`, and `data_cache` are NOT pulled in even though
they're upstream of `compute`.

If you want transitive upstream, list each dir explicitly or use a tool above
Terragrunt (Terramate `terramate run --changed`) that computes the closure.

Verified locally with Terragrunt 0.93.10: target `compute` runs 5 units (compute
+ 4 direct parents); target `edge` runs 3 (edge + compute + dns); target
`data_db` runs 2 (data_db + network).

### Scenario 7 — target two siblings

```bash
terragrunt run --all plan \
  --queue-include-dir=data_db \
  --queue-include-dir=data_cache
```

Queue: `[network, data_db, data_cache]`. `network` joins because both
targets depend on it; the other roots and downstreams stay out.

### Scenario 8 — exclude a unit

```bash
terragrunt run --all plan --queue-exclude-dir=edge
```

Runs everything except `edge`. Useful when one unit is broken and you want to
roll the rest forward.

### Scenario 9 — destroy footgun

```bash
# DO NOT run this verbatim — read the explanation first
terragrunt run --all destroy --queue-include-dir=data_db
```

Default expansion includes upstream → queue is `[network, data_db]` → destroy
order reverses → `data_db` destroyed first, then **`network`** destroyed too.
Almost certainly not what you want.

The safe form:

```bash
terragrunt run --all destroy --queue-include-dir=data_db --queue-strict-include
```

Or just:

```bash
cd data_db && terragrunt destroy
```

Either of these destroys only `data_db`. `compute` and `edge` are not touched,
but their next plan will fail or replan because the `dependency "db"` read
returns nothing.

### Scenario 10 — run from inside a single unit

```bash
cd compute
terragrunt plan
```

Equivalent to `--queue-strict-include` on that one unit, but you save the
typing. Dependency blocks resolve from the cwd; reads `../network`,
`../iam`, `../data_db`, `../data_cache` for their outputs.

## What's identical between implicit and explicit

Same DAG. Same `dependency` blocks. Same expansion rules. Same destroy
footgun. Same downstream non-expansion. Same logical drift after a partial
apply.

The only delta: **the path you put after `--queue-include-dir`**. Implicit
uses `data_db`; explicit uses `.terragrunt-stack/data_db`.

## Cleaning up

```bash
# implicit
cd new/local/implicit
terragrunt run --all destroy
rm -rf */.terragrunt-cache */terraform.tfstate*

# explicit
cd new/local/explicit
terragrunt run --all destroy
rm -rf .terragrunt-stack    # remove generated tree
```

Local backend state files live under each unit's `.terragrunt-cache/.../`
working directory. The destroy command above unwinds the DAG in reverse
(downstream-first), then the `rm -rf` removes the cache.
