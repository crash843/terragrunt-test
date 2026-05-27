variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

resource "terraform_data" "app" {
  input            = "${var.name}@${var.vpc_id}"
  triggers_replace = [timestamp()]
}

output "url" {
  value = "https://${var.name}.${var.vpc_id}.example.com"
}
