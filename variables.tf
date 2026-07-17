variable "abort_incomplete_multipart_upload_days" {
  type        = number
  description = "Number of days to abort incomplete multipart uploads."
  default     = 7

  validation {
    condition     = var.abort_incomplete_multipart_upload_days > 0
    error_message = "Abort incomplete multipart upload days must be greater than 0."
  }
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

variable "additional_policy_statements" {
  type        = any
  description = <<-EOT
    Additional IAM policy statements to include in the bucket policy, merged
    with the statements the module always applies (default access, SSL-only,
    and malware scanning).
    EOT
  default     = []
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
    KMS encryption settings for the bucket.

    - `allowed_principals`: List of AWS principal ARNs to allow to use the KMS
      key. This is used to grant access to other resources that need to use the
      key, such as ECS task roles. Only applies when `create` is `true`.
    - `arn`: ARN of an existing KMS key to use for bucket encryption. Required
      when `create` is `false`.
    - `create`: Whether to create a new KMS key for the bucket. When `false`,
      `arn` must be provided.
    - `recovery_period`: Number of days to recover the created KMS key after
      deletion. Must be between `7` and `30`. Only applies when `create` is
      `true`.
    EOT
  default     = {}

  validation {
    condition     = var.kms.create || var.kms.arn != null
    error_message = "When kms.create is false, kms.arn must be provided."
  }

  validation {
    condition     = var.kms.arn == null || var.kms.create == false
    error_message = "When kms.arn is provided, kms.create must be false."
  }

  validation {
    condition     = var.kms.recovery_period > 6 && var.kms.recovery_period < 31
    error_message = "Recovery period must be between 7 and 30."
  }
}

variable "logging_bucket" {
  type        = string
  description = "S3 bucket to send access logs to."
}

variable "malware_scanning" {
  type = object({
    enabled         = optional(bool, false)
    object_prefixes = optional(list(string), [])
    restrict_access = optional(bool, false)
    tag_objects     = optional(bool, true)
  })
  description = <<-EOT
    Malware scanning settings for the bucket, using GuardDuty Malware Protection
    for S3.

    - `enabled`: Whether to enable malware scanning on the bucket. Objects are
      scanned as they are uploaded.
    - `object_prefixes`: List of object key prefixes to scan. When empty, all
      objects in the bucket are scanned.
    - `restrict_access`: Whether to deny `s3:GetObject` for objects that are not
      tagged `GuardDutyMalwareScanStatus = NO_THREATS_FOUND`. The scan role is
      exempt so scanning can still read objects. Requires `enabled` and
      `tag_objects` to be `true`.
    - `tag_objects`: Whether GuardDuty should tag objects with the scan result
      (`GuardDutyMalwareScanStatus`).
    EOT
  default     = {}

  validation {
    condition     = !var.malware_scanning.restrict_access || var.malware_scanning.enabled
    error_message = <<-EOT
      malware_scanning.enabled must be true when restrict_access is enabled.
      EOT
  }

  validation {
    condition     = !var.malware_scanning.restrict_access || var.malware_scanning.tag_objects
    error_message = <<-EOT
      malware_scanning.tag_objects must be true when restrict_access is enabled.
      EOT
  }
}

variable "name" {
  type        = string
  description = <<-EOT
    Name of the bucket. The project and environment will be prepended to this
    automatically.
    EOT
}

variable "noncurrent_version_expiration_days" {
  type        = number
  description = "Number of days to expire noncurrent versions of objects."
  default     = 30

  validation {
    condition     = var.noncurrent_version_expiration_days > 0
    error_message = "Noncurrent version expiration days must be greater than 0."
  }
}

variable "object_lock" {
  type = object({
    days    = optional(number, 30)
    enabled = optional(bool, true)
    mode    = optional(string, "GOVERNANCE")
  })
  description = <<-EOT
    Object lock settings for the bucket.

    - `days`: Number of days for the default retention period. Set to `null` to
      enable object lock without a default retention rule. Only applies when
      `enabled` is `true`.
    - `enabled`: Whether to enable object lock on the bucket. Can be enabled on
      an existing bucket, but cannot be disabled once enabled.
    - `mode`: Default retention mode. Must be `GOVERNANCE` or `COMPLIANCE`. Only
      applies when `days` is set.
    EOT
  default     = {}

  validation {
    condition     = var.object_lock.days == null || var.object_lock.days > 0
    error_message = "Object lock retention days must be greater than 0."
  }

  validation {
    condition     = var.object_lock.days == null || var.object_lock.enabled
    error_message = <<-EOT
      Object lock must be enabled to set a default retention period.
      EOT
  }

  validation {
    condition     = var.object_lock.days == null || contains(["GOVERNANCE", "COMPLIANCE"], var.object_lock.mode)
    error_message = <<-EOT
      Object lock mode must be GOVERNANCE or COMPLIANCE when days is set.
      EOT
  }
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
  default     = "internal"

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
    List of storage class transitions to apply to the buckets lifecycle
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
