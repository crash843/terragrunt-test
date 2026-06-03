include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_terragrunt_dir()}"
}

inputs = {
  service_name = values.service_name
}
