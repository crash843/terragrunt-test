# Local-run root config. No remote backend declared — Terragrunt uses a local
# backend in each unit's .terragrunt-cache directory. Good enough for trying
# out run-all targeting and watching the DAG; not for shared state.

inputs = {
  stack_name = "local-implicit"
}
