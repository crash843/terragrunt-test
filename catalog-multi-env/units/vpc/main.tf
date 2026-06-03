variable "name" {
  type = string
}

variable "cidr" {
  type = string
}

# terraform_data is built in (no provider, no creds). triggers_replace on
# timestamp() forces replacement every apply, so vpc_id below changes every run
# and any downstream consumer sees a fresh value.
resource "terraform_data" "vpc" {
  input            = "${var.name}/${var.cidr}"
  triggers_replace = [timestamp()]
}

output "vpc_id" {
  value = terraform_data.vpc.id
}

output "name" {
  value = var.name
}
