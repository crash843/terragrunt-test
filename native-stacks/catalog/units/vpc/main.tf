variable "cidr" {
  type = string
}

# terraform_data is a built-in resource (Terraform 1.4+, OpenTofu) so this
# fixture needs no provider and no cloud credentials. triggers_replace on
# timestamp() forces a replacement every run, so each plan shows a change.
resource "terraform_data" "vpc" {
  input            = var.cidr
  triggers_replace = [timestamp()]
}

output "vpc_id" {
  value = "vpc-${substr(md5(var.cidr), 0, 8)}"
}
