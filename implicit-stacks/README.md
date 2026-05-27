# implicit-stacks

Units with dependencies that form a stack **without** a `terragrunt.stack.hcl`.
The stack is implied by the directory layout plus `dependency` blocks.

```
implicit-stacks/
├── root.hcl                # shared config, included by each unit
├── vpc/{terragrunt.hcl,main.tf}
├── db/{terragrunt.hcl,main.tf}    # depends on vpc
└── app/{terragrunt.hcl,main.tf}   # depends on vpc + db
```

Dependency DAG: `vpc -> db -> app` (app also reads vpc directly).

Run it:

```bash
terragrunt run --all plan      # ordered: vpc, then db, then app
terragrunt run --all apply
terragrunt run --all output
```

This is the model Scalr already supports today (a run-all workspace): units are
discovered with `terragrunt find --dag --json`, every unit lives in the repo, and
one run plans/applies all of them in dependency order. Contrast with
`../native-stacks`, where units are generated from declared sources and are not
in the repo.
