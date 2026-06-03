# Shared root config. Included by every generated unit via find_in_parent_folders.
# State backend is intentionally not declared here — when you enable "Use run-all"
# on Spacelift you must also disable "Manage state" for native stacks, and either
# declare an S3/GCS remote_state block (production) or let Terraform fall back to
# the local backend (test fixture).

inputs = {
  environment = "shared"
}
