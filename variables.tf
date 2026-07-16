variable "abort_incomplete_multipart_upload_days" {
  type        = number
  description = "Number of days to abort incomplete multipart uploads."
  default     = 7

  validation {
    condition     = var.abort_incomplete_multipart_upload_days > 0
    error_message = "Abort incomplete multipart upload days must be greater than 0."
  }
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

variable "project" {
  type        = string
  description = <<-EOT
    Project that these resources are supporting. This is used in the prefix to
    all resource names.
    EOT
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
