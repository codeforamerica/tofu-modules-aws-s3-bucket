output "bucket_name" {
  description = "Name of the created bucket."
  value       = module.this.bucket
}

output "bucket_arn" {
  description = "Full ARN of the created bucket."
  value       = module.this.arn
}

output "bucket_domain_name" {
  description = <<-EOT
    Domain name of the created bucket, in the format
    `bucketname.s3.amazonaws.com`.
    EOT
  value       = module.this.bucket_domain_name
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for bucket encryption."
  value       = local.kms_key_arn
}

output "malware_protection_plan_arn" {
  description = <<-EOT
    ARN of the GuardDuty malware protection plan, if malware protection is
    enabled.
    EOT
  value       = var.enable_malware_protection ? aws_guardduty_malware_protection_plan.this["this"].arn : null
}
