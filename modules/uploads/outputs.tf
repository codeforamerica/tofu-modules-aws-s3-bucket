output "bucket_name" {
  description = "Name of the created bucket."
  value       = module.bucket.bucket_name
}

output "bucket_arn" {
  description = "Full ARN of the created bucket."
  value       = module.bucket.bucket_arn
}

output "bucket_domain_name" {
  description = <<-EOT
    Domain name of the created bucket, in the format
    `bucketname.s3.amazonaws.com`.
    EOT
  value       = module.bucket.bucket_domain_name
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for bucket encryption."
  value       = module.bucket.kms_key_arn
}

output "malware_scanning_role_arn" {
  description = "ARN of the IAM role GuardDuty assumes to scan objects."
  value       = module.bucket.malware_scanning_role_arn
}
