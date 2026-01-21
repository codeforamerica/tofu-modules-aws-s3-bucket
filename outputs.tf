output "bucket_name" {
  description = "Name of the created bucket."
  value       = module.this.bucket
}

output "bucket_arn" {
  description = "ARN of the created bucket."
  value       = module.this.arn
}

output "bucket_domain_name" {
  description = "Domain name of the created bucket."
  value       = module.this.bucket_domain_name
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for bucket encryption."
  value       = local.kms_key_arn
}
