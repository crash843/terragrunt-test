include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_terragrunt_dir()}"
}

# app depends on both vpc and db, so the DAG is vpc -> db -> app (app also reads
# vpc directly). run --all walks this order.
dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_id = "vpc-00000000"
  }
}

dependency "db" {
  config_path = "../db"
  mock_outputs = {
    db_endpoint = "db.mock.internal"
  }
}

inputs = {
  vpc_id      = dependency.vpc.outputs.vpc_id
  db_endpoint = dependency.db.outputs.db_endpoint
}
