# Shared root config. Included by every generated unit via find_in_parent_folders.
#
# State is stored in Scalr via its TFE-compatible remote backend, one Scalr
# workspace per unit named "explicit-<env>-<unit>" (e.g. explicit-dev-vpc).
# Spacelift "Manage state" stays off — Spacelift can't inject a backend into
# generated stack units, so we declare our own here.
#
# Required setup (details in README.md):
#   1. Create four Scalr workspaces ahead of time, with execution mode "local"
#      so Scalr only stores state:
#        explicit-dev-vpc    explicit-dev-app
#        explicit-prod-vpc   explicit-prod-app
#   2. Generate a Scalr API token with state read/write on those workspaces.
#   3. On the Spacelift stack, set the env var:
#        TF_TOKEN_<scalr-host-dots-as-underscores> = <token>
#      e.g. TF_TOKEN_acme_scalr_io for hostname acme.scalr.io.
#   4. Replace the hostname and organization placeholders below.

locals {
  # The generated unit's directory name ("vpc" or "app").
  unit = basename(get_terragrunt_dir())
  # path_relative_to_include() resolves to "envs/<env>/.terragrunt-stack/<unit>";
  # element index 1 is the env name.
  env = element(split("/", path_relative_to_include()), 1)
  ws_name = "explicit-${local.env}-${local.unit}"
}

remote_state {
  backend = "remote"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
  config = {
    hostname     = "<your-scalr-host>"      # e.g. acme.scalr.io
    organization = "<your-scalr-account>"   # Scalr account name
    workspaces = {
      name = local.ws_name
    }
  }
}

inputs = {
  environment = "shared"
}
