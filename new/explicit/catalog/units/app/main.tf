variable "name" {
  type = string
}

variable "instances" {
  type = number
}

variable "vpc_id" {
  type = string
}

variable "vpc_name" {
  type = string
}

resource "terraform_data" "app" {
  input            = "${var.name}x${var.instances}@${var.vpc_id}"
  triggers_replace = [timestamp()]
}

output "url" {
  value = "https://${var.name}.${var.vpc_name}.example.com"
}

output "instance_count" {
  value = var.instances
}
