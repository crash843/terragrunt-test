# Shared root for the Scalr-driver demo. Included by every generated unit.
#
# State is stored in Scalr via its TFE-compatible remote backend, one Scalr
# workspace per generated unit named "scalr-<unit>" (scalr-vpc, scalr-app).
# The driver workspace running run-all does NOT hold its own state — each unit
# initialises a backend pointing at its own state-only workspace.
#
# Required setup (see README.md):
#   1. Driver workspace in Scalr (this fixture's home):
#        working_directory = new/scalr
#        terragrunt_version = 0.78+
#        tg_use_run_all = true
#        remote_backend = false   (Scalr forbids run-all + managed state)
#   2. Two state-only workspaces with execution mode "local":
#        scalr-vpc, scalr-app
#   3. Scalr API token with state read/write on the two state-only workspaces,
#      set on the driver workspace as the env var:
#        TF_TOKEN_<scalr-host-dots-as-underscores> = <token>
#      For mainiacp.ik-test-cv-error.testenv.scalr.dev the env var name is:
#        TF_TOKEN_mainiacp_ik-test-cv-error_testenv_scalr_dev
#   4. Replace <your-scalr-environment-name> below with the Scalr environment
#      name (the env where the state-only workspaces live).

locals {
  unit    = basename(get_terragrunt_dir())   # "vpc" or "app"
  ws_name = "scalr-${local.unit}"
}

remote_state {
  backend = "remote"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
  config = {
    hostname     = "mainiacp.ik-test-cv-error.testenv.scalr.dev"
    organization = "<your-scalr-environment-name>"
    workspaces = {
      name = local.ws_name
    }
  }
}

inputs = {
  environment = "scalr-demo"
}
