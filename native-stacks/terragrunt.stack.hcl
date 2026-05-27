# Explicit (native) Terragrunt stack.
#
# Two units sourced from ../catalog (repo root, OUTSIDE this working directory on
# purpose — if the unit templates lived under native-stacks/ they would be
# discovered as standalone units and fail, since `values.*` only exists in
# generated units). `terragrunt stack generate` copies each `source` into
# .terragrunt-stack/<path>/ and writes a terragrunt.values.hcl holding the
# `values` below, which is where `values.cidr` etc. resolve.
#
#   terragrunt stack generate     # -> .terragrunt-stack/{vpc,app}/
#   terragrunt stack run plan
#   terragrunt stack run apply
#   terragrunt stack output
#   terragrunt stack clean        # remove .terragrunt-stack/

unit "vpc" {
  source = "../catalog/units/vpc"
  path   = "vpc"
  values = {
    cidr = "10.0.0.0/16"
  }
}

unit "app" {
  source = "../catalog/units/app"
  path   = "app"
  values = {
    name = "web"
  }
}
