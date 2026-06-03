# Single native stack driven by one Scalr workspace. Two units stamped from
# the shared catalog at repo root (outside this directory, so run-all doesn't
# discover the templates as standalone units).

unit "vpc" {
  source = "../../catalog-multi-env/units/vpc"
  path   = "vpc"
  values = {
    name = "scalr"
    cidr = "10.10.0.0/16"
  }
}

unit "app" {
  source = "../../catalog-multi-env/units/app"
  path   = "app"
  values = {
    name      = "web"
    instances = 2
  }
}
