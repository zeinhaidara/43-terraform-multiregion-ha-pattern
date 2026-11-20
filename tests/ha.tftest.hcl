# Mocked provider only. Nothing is created in AWS.
mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { region = "eu-west-2" }
  }
}

variables {
  name               = "orders"
  secondary_region   = "us-east-1"
  zone_id            = "Z0123456789EXAMPLE"
  record_name        = "app.example.com"
  primary_endpoint   = "app-euw2.example.com"
  secondary_endpoint = "app-use1.example.com"
}

run "active_passive_wiring" {
  command = apply

  assert {
    condition     = one(aws_dynamodb_table.this.replica[*].region_name) == "us-east-1"
    error_message = "table must have one replica in the secondary region"
  }

  assert {
    condition     = aws_dynamodb_table.this.stream_enabled && aws_dynamodb_table.this.stream_view_type == "NEW_AND_OLD_IMAGES"
    error_message = "global tables need streams with new and old images"
  }

  assert {
    condition     = aws_dynamodb_table.this.point_in_time_recovery[0].enabled && one(aws_dynamodb_table.this.replica[*].point_in_time_recovery)
    error_message = "PITR must be on in both regions"
  }

  assert {
    condition     = aws_route53_record.primary.failover_routing_policy[0].type == "PRIMARY" && aws_route53_record.secondary.failover_routing_policy[0].type == "SECONDARY"
    error_message = "records must be PRIMARY and SECONDARY"
  }

  assert {
    condition     = aws_route53_record.primary.health_check_id == aws_route53_health_check.primary.id
    error_message = "the primary record must use the health check"
  }

  assert {
    condition     = aws_route53_record.secondary.health_check_id == null
    error_message = "the secondary record has no health check, so it is the fallback"
  }

  assert {
    condition     = aws_route53_health_check.primary.fqdn == "app-euw2.example.com" && aws_route53_health_check.primary.resource_path == "/healthz"
    error_message = "health check must probe the primary endpoint"
  }

  assert {
    condition     = aws_route53_record.primary.ttl == 60 && aws_route53_record.secondary.ttl == 60
    error_message = "failover records use the low TTL"
  }
}

run "same_region_rejected" {
  command = plan

  variables {
    secondary_region = "eu-west-2"
  }

  expect_failures = [aws_dynamodb_table.this]
}

run "same_endpoint_rejected" {
  command = plan

  variables {
    secondary_endpoint = "app-euw2.example.com"
  }

  expect_failures = [aws_route53_record.primary]
}

run "long_ttl_rejected" {
  command = plan

  variables {
    dns_ttl = 3600
  }

  expect_failures = [var.dns_ttl]
}

run "bad_health_path_rejected" {
  command = plan

  variables {
    health_check_path = "healthz"
  }

  expect_failures = [var.health_check_path]
}

run "bad_zone_id_rejected" {
  command = plan

  variables {
    zone_id = "example.com"
  }

  expect_failures = [var.zone_id]
}
