# Common settings shared by every generated unit.
# In Scalr the state backend is managed for you, so no remote_state block here.
# For local runs Terragrunt falls back to a local backend.

inputs = {
  environment = "dev"
}
