variable "abort_incomplete_multipart_upload_days" {
  type        = number
  description = "Number of days to abort incomplete multipart uploads."
  default     = 7

  validation {
    condition     = var.abort_incomplete_multipart_upload_days > 0
    error_message = "Abort incomplete multipart upload days must be greater than 0."
  }
}

variable "allowed_principals" {
  type        = list(string)
  description = <<-EOT
    List of AWS principal ARNs to allow to use the KMS key. This is used to
    grant access to other resources that need to use the key, such as ECS task
    roles.
    EOT
  default     = []
}

variable "encryption_key_arn" {
  type        = string
  description = <<-EOT
    ARN of the KMS key to use for S3 bucket encryption. If not provided, a new
    KMS key will be created.
    EOT
  default     = null
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

variable "key_recovery_period" {
  type        = number
  description = <<-EOT
    Number of days to recover the created KMS key after deletion. Must be
    between `7` and `30`.
    EOT
  default     = 30

  validation {
    condition     = var.key_recovery_period > 6 && var.key_recovery_period < 31
    error_message = "Key recovery period must be between 7 and 30."
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
