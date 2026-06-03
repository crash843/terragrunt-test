variable "cidr" {
  type    = string
  default = "10.0.0.0/16"
}

resource "terraform_data" "vpc" {
  input            = var.cidr
  triggers_replace = [timestamp()]
}

# Output references the resource id so it changes every apply, which lets a
# downstream Spacelift stack triggered by spacelift_stack_dependency_reference
# re-run on every networking apply (Spacelift skips downstream if the referenced
# output didn't change).
output "vpc_id" {
  value = terraform_data.vpc.id
}
