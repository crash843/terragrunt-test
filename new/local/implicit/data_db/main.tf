variable "vpc_id" {
  type = string
}

resource "terraform_data" "db" {
  input            = "db@${var.vpc_id}"
  triggers_replace = [timestamp()]
}

output "db_endpoint" {
  value = "db-${substr(terraform_data.db.id, 0, 8)}.${var.vpc_id}.internal"
}
