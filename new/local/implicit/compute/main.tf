variable "vpc_id" {
  type = string
}

variable "role_arn" {
  type = string
}

variable "db_endpoint" {
  type = string
}

variable "cache_endpoint" {
  type = string
}

resource "terraform_data" "compute" {
  input = jsonencode({
    vpc   = var.vpc_id
    role  = var.role_arn
    db    = var.db_endpoint
    cache = var.cache_endpoint
  })
  triggers_replace = [timestamp()]
}

output "api_url" {
  value = "https://api-${substr(terraform_data.compute.id, 0, 8)}.${var.vpc_id}.svc.local"
}
