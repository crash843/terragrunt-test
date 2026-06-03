# Same 7-unit DAG as ../implicit/, stamped from ../catalog/units.
#
#   roots: network, iam, dns
#   data_db    deps network
#   data_cache deps network
#   compute    deps network, iam, data_db, data_cache
#   edge       deps compute, dns
#
# Run from this directory:
#   terragrunt run --all plan
#   terragrunt run --all apply

unit "network" {
  source = "../catalog/units/network"
  path   = "network"
  values = {
    cidr = "10.0.0.0/16"
  }
}

unit "iam" {
  source = "../catalog/units/iam"
  path   = "iam"
  values = {
    service_name = "platform"
  }
}

unit "dns" {
  source = "../catalog/units/dns"
  path   = "dns"
  values = {
    zone = "demo.local"
  }
}

unit "data_db" {
  source = "../catalog/units/data_db"
  path   = "data_db"
  values = {}
}

unit "data_cache" {
  source = "../catalog/units/data_cache"
  path   = "data_cache"
  values = {}
}

unit "compute" {
  source = "../catalog/units/compute"
  path   = "compute"
  values = {}
}

unit "edge" {
  source = "../catalog/units/edge"
  path   = "edge"
  values = {}
}
