variable "cidr" {
  type    = string
  default = "10.0.0.0/16"
}

# Built-in resource (Terraform 1.4+, OpenTofu) — no provider, no cloud creds.
# triggers_replace on timestamp() forces a replacement every run, so each plan
# shows a change.
resource "terraform_data" "vpc" {
  input            = var.cidr
  triggers_replace = [timestamp()]
}

output "vpc_id" {
  value = "vpc-${substr(md5(var.cidr), 0, 8)}"
}
