# Prod environment. Same shape as dev, different values.

unit "vpc" {
  source = "../../../catalog-multi-env/units/vpc"
  path   = "vpc"
  values = {
    name = "prod"
    cidr = "10.1.0.0/16"
  }
}

unit "app" {
  source = "../../../catalog-multi-env/units/app"
  path   = "app"
  values = {
    name      = "web"
    instances = 6
  }
}
