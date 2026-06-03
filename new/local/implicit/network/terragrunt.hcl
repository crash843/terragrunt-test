include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_terragrunt_dir()}"
}

inputs = {
  cidr = "10.0.0.0/16"
}
