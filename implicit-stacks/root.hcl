# Common settings shared by every unit.
# In Scalr the state backend is managed for you; for local runs Terragrunt
# falls back to a local backend.

inputs = {
  environment = "dev"
}
