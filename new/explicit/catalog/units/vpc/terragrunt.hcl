# vpc unit template. `terragrunt stack generate` (or `run --all` on 0.78+) copies
# this directory into <env>/.terragrunt-stack/vpc/ and writes a
# terragrunt.values.hcl next to it, so values.* resolves to the per-env values
# declared in envs/<env>/terragrunt.stack.hcl.

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_terragrunt_dir()}"
}

inputs = {
  name = values.name
  cidr = values.cidr
}
