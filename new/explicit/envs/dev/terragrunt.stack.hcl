# Dev environment. Two units stamped from ../../catalog with dev values.
# Set Spacelift project_root to new/explicit/envs/dev, "Use run-all" on,
# "Manage state" off.

unit "vpc" {
  source = "../../catalog/units/vpc"
  path   = "vpc"
  values = {
    name = "dev"
    cidr = "10.0.0.0/16"
  }
}

unit "app" {
  source = "../../catalog/units/app"
  path   = "app"
  values = {
    name      = "web"
    instances = 1
  }
}
