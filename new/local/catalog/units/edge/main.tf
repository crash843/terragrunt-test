variable "api_url" {
  type = string
}

variable "zone_id" {
  type = string
}

variable "zone" {
  type = string
}

resource "terraform_data" "edge" {
  input            = "${var.api_url}|${var.zone_id}"
  triggers_replace = [timestamp()]
}

output "cdn_url" {
  value = "https://cdn-${substr(terraform_data.edge.id, 0, 8)}.${var.zone}"
}
