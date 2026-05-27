# Unit template. `stack generate` copies this whole directory into
# .terragrunt-stack/vpc/ and writes a terragrunt.values.hcl beside it, so
# `values.*` resolves to the values from the `unit "vpc"` block.

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_terragrunt_dir()}"
}

inputs = {
  cidr = values.cidr
}
