module "bucket" {
  source = "../.."

  abort_incomplete_multipart_upload_days = var.abort_incomplete_multipart_upload_days
  add_suffix                             = var.add_suffix
  additional_policy_statements           = var.additional_policy_statements
  environment                            = var.environment
  expiration                             = var.expiration
  force_delete                           = var.force_delete
  kms                                    = var.kms
  logging_bucket                         = var.logging_bucket
  name                                   = var.name
  noncurrent_version_expiration_days     = var.noncurrent_version_expiration_days
  object_lock                            = var.object_lock
  project                                = var.project
  sensitivity                            = var.sensitivity
  storage_class_transitions              = var.storage_class_transitions

  # Identify these buckets by their purpose.
  tags = merge({ use = "file-uploads" }, var.tags)

  # Malware scanning is always enabled for upload buckets, and objects are
  # always tagged with the scan result so it can be acted on per object. The
  # remaining scan options are overridable.
  malware_scanning = {
    enabled         = true
    object_prefixes = var.malware_scanning.object_prefixes
    restrict_access = var.malware_scanning.restrict_access
    tag_objects     = true
  }
}
