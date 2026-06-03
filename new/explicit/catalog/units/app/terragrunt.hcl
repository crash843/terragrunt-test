include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_terragrunt_dir()}"
}

# app consumes vpc's output. After generate the units sit side by side under
# .terragrunt-stack/, so ../vpc resolves to the generated vpc.
dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_id = "vpc-00000000"
    name   = "mock"
  }
}

inputs = {
  name      = values.name
  instances = values.instances
  vpc_id    = dependency.vpc.outputs.vpc_id
  vpc_name  = dependency.vpc.outputs.name
}
