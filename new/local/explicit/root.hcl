# Local-run root config for the explicit (native) stack. No remote backend
# declared — Terragrunt uses a local backend in each generated unit's
# .terragrunt-cache directory. Good for trying out run-all targeting and
# watching the DAG; not for shared state.

inputs = {
  stack_name = "local-explicit"
}
