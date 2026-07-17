output "arn" {
  description = "Full ARN of the created bucket."
  value       = module.bucket.arn
}

output "domain_name" {
  description = <<-EOT
    Domain name of the created bucket, in the format
    `bucketname.s3.amazonaws.com`.
    EOT
  value       = module.bucket.domain_name
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for bucket encryption."
  value       = module.bucket.kms_key_arn
}

output "malware_scanning_role_arn" {
  description = "ARN of the IAM role GuardDuty assumes to scan objects."
  value       = module.bucket.malware_scanning_role_arn
}

output "name" {
  description = "Name of the created bucket."
  value       = module.bucket.name
}
