locals {
  region = coalesce(var.region, data.aws_region.current.region)

  # Number of random characters in the suffix appended when add_suffix is
  # enabled. The suffix also includes a leading hyphen.
  suffix_length = 8

  base_name = join("-", compact([var.project, var.state, var.environment, var.name]))

  # When a suffix is added, truncate the base name so the base plus the suffix
  # stays within the 63-character bucket name limit, stripping any trailing
  # hyphen left at the truncation boundary.
  max_base_length = 63 - local.suffix_length - 1
  truncated_base  = replace(substr(local.base_name, 0, local.max_base_length), "/-+$/", "")

  bucket_name = var.add_suffix ? "${local.truncated_base}-${one(random_string.suffix[*].result)}" : local.base_name

  # Base bucket policy rendered from the template, before merging in any
  # additional statements provided by the caller.
  base_bucket_policy = yamldecode(templatefile("${path.module}/templates/bucket-policy.yaml.tftpl", {
    account          = data.aws_caller_identity.identity.account_id
    bucket           = local.bucket_name
    partition        = data.aws_partition.current.partition
    restrict_malware = var.malware_scanning.restrict_access
    scan_role_arn    = var.malware_scanning.restrict_access ? aws_iam_role.malware_scanning["this"].arn : ""
  }))

  kms_key_arn = var.kms.create ? aws_kms_key.bucket["this"].arn : var.kms.arn
  tags        = merge({ sensitivity = var.sensitivity }, var.tags)

  # Default to us-west-2, or us-east-1 if the bucket is already out west.
  replica_region      = coalesce(var.replication.region, startswith(local.region, "us-west") ? "us-east-1" : "us-west-2")
  replica_bucket_name = "${local.bucket_name}-replica"

  # Where the replica bucket's key comes from. A caller-provided key always
  # wins. Otherwise a module-created primary key is replicated when it's
  # multi-region, and a new key is created when it isn't. The key's actual
  # multi_region attribute is used, since kms.multi_region is ignored after the
  # key is created.
  replica_kms_source = (
    !var.replication.enabled ? "none"
    : var.replication.kms_arn != null ? "provided"
    : !var.kms.create ? "none"
    : aws_kms_key.bucket["this"].multi_region ? "replica"
    : "create"
  )
  replica_kms_key_arn = (
    local.replica_kms_source == "provided" ? var.replication.kms_arn
    : local.replica_kms_source == "replica" ? aws_kms_replica_key.replica["this"].arn
    : local.replica_kms_source == "create" ? aws_kms_key.replica["this"].arn
    : null
  )
}
