# native-stacks

Explicit Terragrunt stack — units declared in `terragrunt.stack.hcl`.

```
native-stacks/
├── terragrunt.stack.hcl        # declares units (source + path + values)
└── root.hcl                    # shared config, included by each unit

../catalog/units/               # unit templates live OUTSIDE the working dir
├── vpc/{terragrunt.hcl,main.tf}    so run --all does not discover them
└── app/{terragrunt.hcl,main.tf}   # depends on vpc
```

The `vpc/` and `app/` working directories do **not** exist until you generate.
`terragrunt stack generate` fetches each unit's `source` and materialises:

```
.terragrunt-stack/
├── vpc/{terragrunt.hcl,main.tf,terragrunt.values.hcl}
└── app/{terragrunt.hcl,main.tf,terragrunt.values.hcl}
```

Run it:

```bash
terragrunt stack generate     # writes .terragrunt-stack/
terragrunt stack run plan
terragrunt stack run apply
terragrunt stack clean        # delete .terragrunt-stack/
```

Requires Terragrunt >= 0.78.0 (Stacks GA). Sources here are local paths; real
stacks usually pull from git or a registry, which is the case to test Scalr's
credential/network handling against.
