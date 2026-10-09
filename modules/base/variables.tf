variable "abort_incomplete_multipart_upload_days" {
  type        = number
  description = "Number of days to abort incomplete multipart uploads."
}

variable "expiration" {
  type        = number
  description = <<-EOT
    Number of days before current object versions expire, or `null` to disable
    expiration.
    EOT
}

variable "force_delete" {
  type        = bool
  description = "Whether to force delete the bucket and its contents."
}

variable "kms_key_arn" {
  type        = string
  description = "ARN of the KMS key used to encrypt the bucket."
}

variable "logging_bucket" {
  type        = string
  description = <<-EOT
    S3 bucket to send access logs to. Must be in the same region as the bucket.
    EOT
  default     = null
}

variable "logging_cloudwatch_log_group_arn" {
  type        = string
  description = <<-EOT
    ARN of a CloudWatch Logs log group to send access logs to. Must be in the
    same region as the bucket.
    EOT
  default     = null
}

variable "name" {
  type        = string
  description = "Full name of the bucket."
}

variable "noncurrent_version_expiration_days" {
  type        = number
  description = "Number of days to expire noncurrent versions of objects."
}

variable "object_lock" {
  type = object({
    days    = number
    enabled = bool
    mode    = string
  })
  description = "Object lock settings for the bucket."
}

variable "policy" {
  type        = string
  description = "JSON bucket policy to apply to the bucket."
}

variable "region" {
  type        = string
  description = "AWS region where the bucket and its resources are created."
}

variable "storage_class_transitions" {
  type = list(object({
    days          = number
    storage_class = string
  }))
  description = "Storage class transitions for the bucket's lifecycle rule."
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources."
  default     = {}
}
