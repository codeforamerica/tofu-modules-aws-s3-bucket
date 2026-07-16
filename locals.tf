locals {
  # Number of random characters in the suffix appended when add_suffix is
  # enabled. The suffix also includes a leading hyphen.
  suffix_length = 8

  base_name = join("-", [var.project, var.environment, var.name])

  # When a suffix is added, truncate the base name so the base plus the suffix
  # stays within the 63-character bucket name limit, stripping any trailing
  # hyphen left at the truncation boundary.
  max_base_length = 63 - local.suffix_length - 1
  truncated_base  = replace(substr(local.base_name, 0, local.max_base_length), "/-+$/", "")

  bucket_name = var.add_suffix ? "${local.truncated_base}-${one(random_string.suffix[*].result)}" : local.base_name

  kms_key_arn = var.kms.create ? aws_kms_key.bucket["this"].arn : var.kms.arn
  logs_path   = "/AWSLogs/${data.aws_caller_identity.identity.account_id}"
}
