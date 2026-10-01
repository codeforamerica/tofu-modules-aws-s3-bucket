# The logging configuration used to be required.
moved {
  from = aws_s3_bucket_logging.this
  to   = aws_s3_bucket_logging.enabled["this"]
}
