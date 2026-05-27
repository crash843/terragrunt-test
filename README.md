# Terragrunt fixtures

Two example projects for exercising Scalr's Terragrunt handling. Both are
provider-free (they use the built-in `terraform_data` resource), so they plan and
apply with no cloud credentials. Both need Terragrunt >= 0.78.0.

| Folder | What it is | Units come from | Scalr support today |
|--------|-----------|-----------------|---------------------|
| [native-stacks](native-stacks/) | Explicit stack: `terragrunt.stack.hcl` declares units, `stack generate` materialises `.terragrunt-stack/` | Declared `source` (fetched), not in repo | Not supported — the feature being scoped |
| [implicit-stacks](implicit-stacks/) | Units wired together with `dependency` blocks, no stack file | Plain directories in the repo | Supported via run-all |

The difference that matters for Scalr: in `implicit-stacks` every unit is already
in the configuration-version snapshot; in `native-stacks` the units are fetched
from external sources at generate time, which is the part that does not fit
Scalr's current "the CV is self-contained" model. See
[fatmouse/docs/terragrunt-stacks.md](../fatmouse/docs/terragrunt-stacks.md).
