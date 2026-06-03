variable "vpc_id" {
  type = string
}

resource "terraform_data" "cache" {
  input            = "cache@${var.vpc_id}"
  triggers_replace = [timestamp()]
}

output "cache_endpoint" {
  value = "cache-${substr(terraform_data.cache.id, 0, 8)}.${var.vpc_id}.internal"
}
