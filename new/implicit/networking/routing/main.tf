variable "vpc_id" {
  type = string
}

resource "terraform_data" "routing" {
  input            = "rt@${var.vpc_id}"
  triggers_replace = [timestamp()]
}

output "route_table_id" {
  value = terraform_data.routing.id
}
