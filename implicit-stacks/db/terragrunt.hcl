include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_terragrunt_dir()}"
}

# db runs after vpc and consumes its output. This dependency edge is what makes
# the three units behave as a stack under `run --all`, with no stack file.
dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_id = "vpc-00000000"
  }
}

inputs = {
  vpc_id = dependency.vpc.outputs.vpc_id
}
