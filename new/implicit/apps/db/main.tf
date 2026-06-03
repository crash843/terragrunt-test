variable "vpc_id" {
  type = string
}

resource "terraform_data" "db" {
  input            = "db@${var.vpc_id}"
  triggers_replace = [timestamp()]
}

output "db_endpoint" {
  value = "db-${terraform_data.db.id}.internal"
}
