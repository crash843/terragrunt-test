include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_terragrunt_dir()}"
}

# app consumes vpc's output. After generate the units sit side by side under
# .terragrunt-stack/, so the relative path ../vpc resolves there.
dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_id = "vpc-00000000"
  }
}

inputs = {
  name   = values.name
  vpc_id = dependency.vpc.outputs.vpc_id
}
