include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_terragrunt_dir()}"
}

# Intra-stack dependency: routing runs after vpc inside the same Spacelift
# stack. terragrunt resolves this DAG under `run --all`.
dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_id = "vpc-00000000"
  }
}

inputs = {
  vpc_id = dependency.vpc.outputs.vpc_id
}
