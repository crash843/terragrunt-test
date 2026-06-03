# Dev environment. Two units stamped from the shared catalog at repo root.
# Catalog lives at /catalog-multi-env so it's outside new/explicit/ — that lets
# a single Spacelift stack point at new/explicit/ and walk both envs without
# discovering the catalog as standalone units.

unit "vpc" {
  source = "../../../catalog-multi-env/units/vpc"
  path   = "vpc"
  values = {
    name = "dev"
    cidr = "10.0.0.0/16"
  }
}

unit "app" {
  source = "../../../catalog-multi-env/units/app"
  path   = "app"
  values = {
    name      = "web"
    instances = 1
  }
}
