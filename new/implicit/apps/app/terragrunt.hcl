include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_terragrunt_dir()}"
}

# Intra-stack dependency on db. vpc_id is NOT read here — it comes through as
# the env var TF_VAR_vpc_id (from Spacelift's stack dependency reference) and
# is picked up directly by Terraform.
dependency "db" {
  config_path = "../db"
  mock_outputs = {
    db_endpoint = "db.mock.internal"
  }
}

inputs = {
  db_endpoint = dependency.db.outputs.db_endpoint
}
