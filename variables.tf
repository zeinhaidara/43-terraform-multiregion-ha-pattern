variable "name" {
  description = "Name of the DynamoDB table and prefix for other resources."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9_.-]{3,200}$", var.name))
    error_message = "name must be 3-200 letters, digits, underscores, dots or hyphens."
  }
}

variable "secondary_region" {
  description = "Region for the DynamoDB replica and the passive stack."
  type        = string

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.secondary_region))
    error_message = "secondary_region must look like us-east-1."
  }
}

variable "hash_key" {
  description = "Partition key attribute name (string type)."
  type        = string
  default     = "pk"

  validation {
    condition     = can(regex("^[a-zA-Z0-9_.-]{1,255}$", var.hash_key))
    error_message = "hash_key must be a valid attribute name."
  }
}

variable "zone_id" {
  description = "Route 53 hosted zone that holds the failover record."
  type        = string

  validation {
    condition     = can(regex("^Z[A-Z0-9]{1,31}$", var.zone_id))
    error_message = "zone_id must look like Z0123456789EXAMPLE."
  }
}

variable "record_name" {
  description = "DNS name clients use, e.g. app.example.com."
  type        = string
}

variable "primary_endpoint" {
  description = "Hostname of the active stack (e.g. its load balancer)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9.-]+\\.[a-z]{2,}$", var.primary_endpoint))
    error_message = "primary_endpoint must be a hostname."
  }
}

variable "secondary_endpoint" {
  description = "Hostname of the passive stack."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9.-]+\\.[a-z]{2,}$", var.secondary_endpoint))
    error_message = "secondary_endpoint must be a hostname."
  }
}

variable "health_check_path" {
  description = "HTTPS path Route 53 probes on the primary endpoint."
  type        = string
  default     = "/healthz"

  validation {
    condition     = startswith(var.health_check_path, "/")
    error_message = "health_check_path must start with /."
  }
}

variable "dns_ttl" {
  description = "TTL of the failover records. Low, so clients follow a failover quickly."
  type        = number
  default     = 60

  validation {
    condition     = var.dns_ttl >= 30 && var.dns_ttl <= 300
    error_message = "dns_ttl must be 30-300 seconds."
  }
}

variable "tags" {
  description = "Tags for taggable resources."
  type        = map(string)
  default     = {}
}
