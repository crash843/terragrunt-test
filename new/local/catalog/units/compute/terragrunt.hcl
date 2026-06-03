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
    cidr   = "10.0.0.0/16"
  }
}

dependency "iam" {
  config_path = "../iam"
  mock_outputs = {
    role_arn = "arn:aws:iam::000000000000:role/mock"
  }
}

dependency "db" {
  config_path = "../data_db"
  mock_outputs = {
    db_endpoint = "db.mock.internal"
  }
}

dependency "cache" {
  config_path = "../data_cache"
  mock_outputs = {
    cache_endpoint = "cache.mock.internal"
  }
}

inputs = {
  vpc_id         = dependency.network.outputs.vpc_id
  role_arn       = dependency.iam.outputs.role_arn
  db_endpoint    = dependency.db.outputs.db_endpoint
  cache_endpoint = dependency.cache.outputs.cache_endpoint
}
