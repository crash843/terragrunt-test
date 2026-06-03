variable "service_name" {
  type    = string
  default = "platform"
}

resource "terraform_data" "iam" {
  input            = var.service_name
  triggers_replace = [timestamp()]
}

output "role_arn" {
  value = "arn:aws:iam::000000000000:role/${var.service_name}-${substr(terraform_data.iam.id, 0, 8)}"
}
