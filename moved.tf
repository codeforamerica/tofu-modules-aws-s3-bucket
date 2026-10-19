# The logging configuration used to be required.
moved {
  from = aws_s3_bucket_logging.this
  to   = module.bucket.aws_s3_bucket_logging.enabled["this"]
}

# The bucket resources moved into the base submodule so the primary and replica
# buckets share one definition.
moved {
  from = aws_s3_bucket.this
  to   = module.bucket.aws_s3_bucket.this
}

moved {
  from = aws_s3_bucket_public_access_block.this
  to   = module.bucket.aws_s3_bucket_public_access_block.this
}

moved {
  from = aws_s3_bucket_ownership_controls.this
  to   = module.bucket.aws_s3_bucket_ownership_controls.this
}

moved {
  from = aws_s3_bucket_versioning.this
  to   = module.bucket.aws_s3_bucket_versioning.this
}

moved {
  from = aws_s3_bucket_object_lock_configuration.this
  to   = module.bucket.aws_s3_bucket_object_lock_configuration.this
}

moved {
  from = aws_s3_bucket_server_side_encryption_configuration.this
  to   = module.bucket.aws_s3_bucket_server_side_encryption_configuration.this
}

moved {
  from = aws_s3_bucket_lifecycle_configuration.this
  to   = module.bucket.aws_s3_bucket_lifecycle_configuration.this
}

moved {
  from = aws_s3_bucket_policy.this
  to   = module.bucket.aws_s3_bucket_policy.this
}

moved {
  from = aws_s3_bucket_logging.enabled
  to   = module.bucket.aws_s3_bucket_logging.enabled
}

moved {
  from = aws_cloudwatch_log_delivery_source.logging
  to   = module.bucket.aws_cloudwatch_log_delivery_source.logging
}

moved {
  from = aws_cloudwatch_log_delivery_destination.logging
  to   = module.bucket.aws_cloudwatch_log_delivery_destination.logging
}

moved {
  from = aws_cloudwatch_log_delivery.logging
  to   = module.bucket.aws_cloudwatch_log_delivery.logging
}
