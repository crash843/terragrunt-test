include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_terragrunt_dir()}"
}

dependency "compute" {
  config_path = "../compute"
  mock_outputs = {
    api_url = "https://api.mock.svc.local"
  }
}

dependency "dns" {
  config_path = "../dns"
  mock_outputs = {
    zone_id = "Zmock00000000"
    zone    = "mock.local"
  }
}

inputs = {
  api_url = dependency.compute.outputs.api_url
  zone_id = dependency.dns.outputs.zone_id
  zone    = dependency.dns.outputs.zone
}
