variable "abort_incomplete_multipart_upload_days" {
  type        = number
  description = "Number of days to abort incomplete multipart uploads."
  default     = 7
}

variable "add_suffix" {
  type        = bool
  description = <<-EOT
    Whether to append a random suffix to the bucket name. This helps ensure the
    bucket name is globally unique. When enabled, the bucket name is truncated
    as needed so the full name stays within the 63-character limit.
    EOT
  default     = false
}

variable "environment" {
  type        = string
  description = <<-EOT
    The environment for the deployment. This is used in the prefix to all
    resource names.
    EOT
  default     = "development"
}

variable "force_delete" {
  type        = bool
  description = <<-EOT
    Whether to force delete the bucket and its contents. Must be set to `true`
    _and_ applied before the bucket can be deleted.
    EOT
  default     = false
}

variable "kms" {
  type = object({
    allowed_principals = optional(list(string), [])
    arn                = optional(string, null)
    create             = optional(bool, true)
    recovery_period    = optional(number, 30)
  })
  description = <<-EOT
    KMS encryption settings for the bucket. See the root module for details.
    EOT
  default     = {}
}

variable "logging_bucket" {
  type        = string
  description = "S3 bucket to send access logs to."
}

variable "malware_scanning" {
  type = object({
    object_prefixes = optional(list(string), [])
    restrict_access = optional(bool, true)
  })
  description = <<-EOT
    Malware scanning settings for the bucket. Scanning is always enabled for
    upload buckets, and objects are always tagged with the scan result; neither
    can be disabled here.

    - `object_prefixes`: List of object key prefixes to scan. When empty, all
      objects in the bucket are scanned.
    - `restrict_access`: Whether to deny `s3:GetObject` for objects that are not
      tagged `GuardDutyMalwareScanStatus = NO_THREATS_FOUND`. Defaults to `true`
      so unscanned or infected uploads are not served. Note that this also
      blocks objects GuardDuty could not scan (for example, files that are too
      large, tagged `UNSUPPORTED`).
    EOT
  default     = {}
}

variable "name" {
  type        = string
  description = <<-EOT
    Name of the bucket. The project and environment will be prepended to this
    automatically.
    EOT
  default     = "uploads"
}

variable "noncurrent_version_expiration_days" {
  type        = number
  description = "Number of days to expire noncurrent versions of objects."
  default     = 30
}

variable "object_lock" {
  type = object({
    days    = optional(number, 30)
    enabled = optional(bool, true)
    mode    = optional(string, "GOVERNANCE")
  })
  description = <<-EOT
    Object lock settings for the bucket. See the root module for details.
    EOT
  default     = {}
}

variable "project" {
  type        = string
  description = <<-EOT
    Project that these resources are supporting. This is used in the prefix to
    all resource names.
    EOT
}

variable "sensitivity" {
  type        = string
  description = <<-EOT
    Data sensitivity level for the bucket. Valid values are `public`,
    `internal`, `confidential`, and `restricted`.
    EOT
  default     = "confidential"

  validation {
    condition     = contains(["public", "internal", "confidential", "restricted"], var.sensitivity)
    error_message = <<-EOT
      Sensitivity must be one of: public, internal, confidential, restricted.
      EOT
  }
}

variable "storage_class_transitions" {
  type = list(object({
    days          = number
    storage_class = string
  }))
  description = <<-EOT
    List of storage class transitions to apply to the bucket's lifecycle
    configuration.
    EOT
  default = [{
    days          = 30
    storage_class = "STANDARD_IA"
  }]
}

variable "tags" {
  type        = map(string)
  description = "Optional tags to be applied to all resources."
  default     = {}
}
