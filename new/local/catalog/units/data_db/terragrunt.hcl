include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_terragrunt_dir()}"
}

dependency "network" {
  config_path = "../network"
  mock_outputs = {
    vpc_id = "vpc-00000000"
  }
}

inputs = {
  vpc_id = dependency.network.outputs.vpc_id
}
