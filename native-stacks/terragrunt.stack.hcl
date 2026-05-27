# Explicit (native) Terragrunt stack.
#
# Two units sourced from the local ./catalog. There is no vpc/ or app/ directory
# in the repo — `terragrunt stack generate` fetches each `source` and writes the
# units into .terragrunt-stack/<path>/, each with a terragrunt.values.hcl holding
# the `values` below.
#
#   terragrunt stack generate     # -> .terragrunt-stack/{vpc,app}/
#   terragrunt stack run plan
#   terragrunt stack run apply
#   terragrunt stack output
#   terragrunt stack clean        # remove .terragrunt-stack/

unit "vpc" {
  source = "./catalog/units/vpc"
  path   = "vpc"
  values = {
    cidr = "10.0.0.0/16"
  }
}

unit "app" {
  source = "./catalog/units/app"
  path   = "app"
  values = {
    name = "web"
  }
}
