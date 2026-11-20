# Example root with placeholder values. Never applied.
terraform {
  required_version = ">= 1.9.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.73.0"
    }
  }
}

# The provider region is the primary (active) region.
provider "aws" {
  region = "eu-west-2"
}

module "orders_ha" {
  source = "../.."

  name               = "orders"
  secondary_region   = "us-east-1"
  zone_id            = "Z0123456789EXAMPLE"
  record_name        = "app.example.com"
  primary_endpoint   = "app-euw2.example.com"
  secondary_endpoint = "app-use1.example.com"

  tags = { project = "orders", owner = "platform@example.com" }
}

output "record_fqdn" {
  value = module.orders_ha.record_fqdn
}
