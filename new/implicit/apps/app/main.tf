variable "vpc_id" {
  type = string
}

variable "db_endpoint" {
  type = string
}

resource "terraform_data" "app" {
  input            = "${var.vpc_id}|${var.db_endpoint}"
  triggers_replace = [timestamp()]
}

output "url" {
  value = "https://app-${terraform_data.app.id}.${var.vpc_id}.example.com"
}
