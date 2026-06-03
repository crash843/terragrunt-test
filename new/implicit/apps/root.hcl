# apps is a separate Spacelift stack from networking. vpc_id is delivered as
# the env var TF_VAR_vpc_id by a Spacelift stack-dependency reference (set up
# in the parent README). Every Terraform process under this stack picks it up
# automatically.

inputs = {
  area = "apps"
}
