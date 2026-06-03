# Prod environment. Same shape as dev, different values, totally separate run.
# Set Spacelift project_root to new/explicit/envs/prod, "Use run-all" on,
# "Manage state" off.

unit "vpc" {
  source = "../../catalog/units/vpc"
  path   = "vpc"
  values = {
    name = "prod"
    cidr = "10.1.0.0/16"
  }
}

unit "app" {
  source = "../../catalog/units/app"
  path   = "app"
  values = {
    name      = "web"
    instances = 6
  }
}
