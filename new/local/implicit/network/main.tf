variable "cidr" {
  type    = string
  default = "10.0.0.0/16"
}

resource "terraform_data" "network" {
  input            = var.cidr
  triggers_replace = [timestamp()]
}

output "vpc_id" {
  value = "vpc-${substr(terraform_data.network.id, 0, 8)}"
}

output "cidr" {
  value = var.cidr
}
