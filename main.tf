data "aws_region" "primary" {}

# --- Data: DynamoDB global table, replicated to the secondary region ------------

resource "aws_dynamodb_table" "this" {
  name         = var.name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = var.hash_key

  attribute {
    name = var.hash_key
    type = "S"
  }

  # Global tables replicate through streams.
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  replica {
    region_name            = var.secondary_region
    point_in_time_recovery = true
  }

  tags = var.tags

  lifecycle {
    precondition {
      condition     = var.secondary_region != data.aws_region.primary.region
      error_message = "secondary_region must differ from the provider's (primary) region."
    }
  }
}

# --- Traffic: Route 53 failover, primary first while healthy ------------------------

resource "aws_route53_health_check" "primary" {
  fqdn              = var.primary_endpoint
  type              = "HTTPS"
  port              = 443
  resource_path     = var.health_check_path
  request_interval  = 30
  failure_threshold = 3
  tags              = merge(var.tags, { Name = "${var.name}-primary" })
}

resource "aws_route53_record" "primary" {
  zone_id         = var.zone_id
  name            = var.record_name
  type            = "CNAME"
  ttl             = var.dns_ttl
  records         = [var.primary_endpoint]
  set_identifier  = "primary"
  health_check_id = aws_route53_health_check.primary.id

  failover_routing_policy {
    type = "PRIMARY"
  }

  lifecycle {
    precondition {
      condition     = var.primary_endpoint != var.secondary_endpoint
      error_message = "primary_endpoint and secondary_endpoint must differ."
    }
  }
}

# No health check: Route 53 treats the secondary as healthy and uses it
# whenever the primary check fails.
resource "aws_route53_record" "secondary" {
  zone_id        = var.zone_id
  name           = var.record_name
  type           = "CNAME"
  ttl            = var.dns_ttl
  records        = [var.secondary_endpoint]
  set_identifier = "secondary"

  failover_routing_policy {
    type = "SECONDARY"
  }
}
