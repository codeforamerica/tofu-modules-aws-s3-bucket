resource "aws_kms_key" "bucket" {
  for_each = var.kms.create ? toset(["this"]) : toset([])

  description             = "Encryption key for bucket ${local.bucket_name}"
  deletion_window_in_days = var.kms.recovery_period
  enable_key_rotation     = true
  region                  = local.region
  multi_region            = var.kms.multi_region

  policy = jsonencode(yamldecode(templatefile("${path.module}/templates/key-policy.yaml.tftpl", {
    account : data.aws_caller_identity.identity.account_id
    bucket : local.bucket_name
    partition : data.aws_partition.current.partition
    principals : var.kms.allowed_principals
  })))

  tags = var.tags

  lifecycle {
    # The multi-region setting can only be configured at creation. Attempting to
    # change it later would cause the resource to be recreated which can result
    # in data lock out.
    ignore_changes = [multi_region]
  }
}

resource "aws_kms_alias" "bucket" {
  for_each = var.kms.create ? toset(["this"]) : toset([])

  name          = "alias/${local.bucket_name}"
  region        = local.region
  target_key_id = aws_kms_key.bucket["this"].arn
}
