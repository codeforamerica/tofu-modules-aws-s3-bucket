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
  value       = local.kms_key_arn
}

output "malware_scanning_role_arn" {
  description = <<-EOT
    ARN of the IAM role GuardDuty assumes to scan objects. `null` when malware
    scanning is disabled.
    EOT
  value       = var.malware_scanning.enabled ? aws_iam_role.malware_scanning["this"].arn : null
}

output "name" {
  description = "Name of the created bucket."
  value       = module.bucket.name
}

output "replica" {
  description = <<-EOT
    Replica bucket details. `null` when replication is disabled.
    EOT
  value = var.replication.enabled ? {
    arn         = module.replica["this"].arn
    kms_key_arn = local.replica_kms_key_arn
    name        = module.replica["this"].name
  } : null
}
