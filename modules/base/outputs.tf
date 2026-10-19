output "arn" {
  description = "Full ARN of the bucket."
  value       = aws_s3_bucket.this.arn
}

output "domain_name" {
  description = <<-EOT
    Domain name of the bucket, in the format `bucketname.s3.amazonaws.com`.
    EOT
  value       = aws_s3_bucket.this.bucket_domain_name
}

output "id" {
  description = "ID of the bucket."
  value       = aws_s3_bucket.this.id
}

output "name" {
  description = "Name of the bucket."
  value       = aws_s3_bucket.this.bucket
}
