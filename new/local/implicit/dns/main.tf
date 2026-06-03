variable "zone" {
  type    = string
  default = "demo.local"
}

resource "terraform_data" "dns" {
  input            = var.zone
  triggers_replace = [timestamp()]
}

output "zone_id" {
  value = "Z${substr(terraform_data.dns.id, 0, 12)}"
}

output "zone" {
  value = var.zone
}
