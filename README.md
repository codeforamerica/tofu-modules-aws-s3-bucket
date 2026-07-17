# AWS S3 Bucket Module

[![GitHub Release][badge-release]][latest-release]

This modules creates an S3 bucket and associated resources like the bucket
policy, encryption, lifecycle configuration, etc. It uses sane defaults to
configure buckets as secure and compliant by default.

In addition to the root module, the [`uploads` submodule][uploads] submodule is
provided as a wrapper for file upload buckets. This submodule uses different
defaults, such as malware scanning enabled, that are appropriate for file
uploads. See [Submodules] below.

## Usage

Add this module to your `main.tf` (or appropriate) file and configure the inputs
to match your desired configuration. For example:

```hcl
module "module_name" {
  source = "github.com/codeforamerica/tofu-modules-aws-s3-bucket?ref=1.0.0"

  project        = "my-project"
  environment    = "development"
  logging_bucket = "my-logging-bucket"
  name           = "documents"
}
```

Make sure you re-run `tofu init` after adding the module to your configuration.

```bash
tofu init
tofu plan
```

## Inputs

| Name                                   | Description                                                                                                                                           | Type           | Default                                         | Required |
| -------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- | -------------- | ----------------------------------------------- | -------- |
| logging_bucket                         | S3 bucket to send access logs to.                                                                                                                     | `string`       | n/a                                             | yes      |
| name                                   | Name of the bucket. The project and environment will be prepended to this automatically.                                                              | `string`       | n/a                                             | yes      |
| project                                | Project that these resources are supporting.                                                                                                          | `string`       | n/a                                             | yes      |
| abort_incomplete_multipart_upload_days | Number of days to abort incomplete multipart uploads.                                                                                                 | `number`       | `7`                                             | no       |
| add_suffix                             | Whether to append a random suffix to the bucket name to help ensure it is globally unique. The bucket name is truncated to keep within 63 characters. | `bool`         | `false`                                         | no       |
| additional_policy_statements           | Additional IAM policy statements to include in the bucket policy, merged with the statements the module always applies.                               | `any`          | `[]`                                            | no       |
| environment                            | The environment for the deployment.                                                                                                                   | `string`       | `"development"`                                 | no       |
| force_delete                           | Whether to force delete the bucket and its contents. Must be set to `true` _and_ applied before the bucket can be deleted.                            | `bool`         | `false`                                         | no       |
| [kms]                                  | KMS encryption settings for the bucket.                                                                                                               | `object`       | `{}`                                            | no       |
| [malware_scanning]                     | Malware scanning settings for the bucket, using GuardDuty Malware Protection for S3.                                                                  | `object`       | `{}`                                            | no       |
| noncurrent_version_expiration_days     | Number of days to expire noncurrent versions of objects.                                                                                              | `number`       | `30`                                            | no       |
| [object_lock]                          | Object lock settings for the bucket.                                                                                                                  | `object`       | `{}`                                            | no       |
| sensitivity                            | Data sensitivity level for the bucket. Valid values are `public`, `internal`, `confidential`, and `restricted`.                                       | `string`       | `internal`                                      | no       |
| [storage_class_transitions]            | List of storage class transitions to apply to the buckets lifecycle configuration.                                                                    | `list(object)` | `[{days  = 30, storage_class = "STANDARD_IA"}]` | no       |
| tags                                   | Optional tags to be applied to all resources.                                                                                                         | `map(string)`  | `{}`                                            | no       |

### kms

Configure how the bucket is encrypted with KMS. By default, the module creates a
new KMS key. To use an existing key instead, set `create` to `false` and provide
`encryption_key_arn`.

| Name               | Description                                                                                                                       | Type           | Default | Required |
| ------------------ | --------------------------------------------------------------------------------------------------------------------------------- | -------------- | ------- | -------- |
| allowed_principals | List of AWS principal ARNs to allow to use the KMS key, such as ECS task roles. Only applies when `create` is `true`.             | `list(string)` | `[]`    | no       |
| arn                | ARN of an existing KMS key to use for bucket encryption. Required when `create` is `false`.                                       | `string`       | `null`  | no       |
| create             | Whether to create a new KMS key for the bucket. When `false`, `arn` must be provided.                                             | `bool`         | `true`  | no       |
| recovery_period    | Number of days to recover the created KMS key after deletion. Must be between `7` and `30`. Only applies when `create` is `true`. | `number`       | `30`    | no       |

### malware_scanning

Enable [GuardDuty Malware Protection for S3][malware-protection] to scan objects
as they are uploaded. When enabled, the module creates an IAM role that
GuardDuty assumes to read, scan, and tag objects, along with a malware
protection plan for the bucket.

Scan results are written to each object as a `GuardDutyMalwareScanStatus` tag
(for example, `NO_THREATS_FOUND` or `THREATS_FOUND`) when `tag_objects` is
`true`. Your application can read this tag to decide whether to serve an object.

Set `restrict_access` to `true` to have the module add a bucket policy statement
that denies `s3:GetObject` for any object not tagged
`GuardDutyMalwareScanStatus = NO_THREATS_FOUND`. The scan role is exempt from
this deny so scanning can still read objects. Note that this also blocks objects
that could not be scanned (for example, tagged `UNSUPPORTED`), and applies to
all principals, including account administrators.

Because the bucket is KMS-encrypted, the scan role is granted `kms:Decrypt` and
`kms:GenerateDataKey` on the key. When the module creates the key
(`kms.create = true`), the key policy delegates to the account, so no additional
configuration is needed. When using an existing key (`kms.create = false`), that
key's policy must allow the scan role (or the account) to decrypt.

GuardDuty Malware Protection for S3 is not available in every region. See the
[AWS documentation][malware-protection] for supported regions and object size
limits.

| Name            | Description                                                                                                                                             | Type           | Default | Required |
| --------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------- | ------- | -------- |
| enabled         | Whether to enable malware scanning on the bucket. Objects are scanned as they are uploaded.                                                             | `bool`         | `false` | no       |
| object_prefixes | List of object key prefixes to scan. When empty, all objects in the bucket are scanned.                                                                 | `list(string)` | `[]`    | no       |
| restrict_access | Whether to deny `s3:GetObject` for objects not tagged `GuardDutyMalwareScanStatus = NO_THREATS_FOUND`. Requires `enabled` and `tag_objects` to be true. | `bool`         | `false` | no       |
| tag_objects     | Whether GuardDuty should tag objects with the scan result (`GuardDutyMalwareScanStatus`).                                                               | `bool`         | `true`  | no       |

### object_lock

Configure [object lock][object-lock] to protect objects from being deleted or
overwritten. Object lock requires versioning, which this module always enables.
By default, a `GOVERNANCE` mode retention rule of 30 days is applied.

> [!NOTE]
> Object lock works by locking the underlying _version_. Files can still be
> overwritten and marked as deleted with object lock enabled, but the version
> marked cannot be.

Object lock is enabled through the `aws_s3_bucket_object_lock_configuration`
resource, so it can be turned on for both new and existing buckets without
replacing them. To enable object lock without a default retention rule, set
`days` to `null`. Note that once object lock is enabled on a bucket, it cannot
be disabled.

| Name    | Description                                                                                                             | Type     | Default        | Required |
| ------- | ----------------------------------------------------------------------------------------------------------------------- | -------- | -------------- | -------- |
| days    | Number of days for the default retention period. Set to `null` to enable object lock without a default retention rule.  | `number` | `30`           | no       |
| enabled | Whether to enable object lock on the bucket. Can be enabled on an existing bucket, but cannot be disabled once enabled. | `bool`   | `true`         | no       |
| mode    | Default retention mode. Must be `GOVERNANCE` or `COMPLIANCE`. Only applies when `days` is set.                          | `string` | `"GOVERNANCE"` | no       |

### storage_class_transitions

You can define multiple [storage class][storage-class] transitions for the
objects in the S3 bucket. This allows you to use a reduced cost storage option
for objects that need to be retained for a longer time, but won't be regularly
accessed.

By default, objects added to the bucket will transition to the infrequent access
storage tier after 30 days. To disable transitions entirely, you can set this
input to an empty list (`[]`).

| Name          | Description                             | Type     | Default | Required |
| ------------- | --------------------------------------- | -------- | ------- | -------- |
| days          | Number of days                          | `number` | n/a     | yes      |
| storage_class | Storage class to transition objects to. | `string` | n/a     | yes      |

Possible values for `storage_class` are `DEEP_ARCHIVE`, `GLACIER`, `GLACIER_IR`,
`INTELLIGENT_TIERING`, `ONEZONE_IA`, `STANDARD_IA`. For more information on the
different storage classes, see the [Amazon S3 documentation][storage-class].

## Outputs

| Name                      | Description                                                                     | Type     |
| ------------------------- | ------------------------------------------------------------------------------- | -------- |
| arn                       | Full ARN of the created bucket.                                                 | `string` |
| domain_name               | Domain name of the created bucket, in the format `bucketname.s3.amazonaws.com`. | `string` |
| kms_key_arn               | ARN of the KMS key used for bucket encryption.                                  | `string` |
| malware_scanning_role_arn | ARN of the IAM role GuardDuty assumes to scan objects. `null` when disabled.    | `string` |
| name                      | Name of the created bucket.                                                     | `string` |

## Submodules

Submodules wrap this module with opinionated defaults for a specific purpose.

| Name      | Description                                                                                 |
| --------- | ------------------------------------------------------------------------------------------- |
| [uploads] | S3 bucket for file uploads, with malware scanning enforced and upload-appropriate defaults. |

Reference a submodule with the `//modules/<name>` subpath, for example:

```hcl
module "uploads" {
  source = "github.com/codeforamerica/tofu-modules-aws-s3-bucket//modules/uploads?ref=1.0.0"

  project        = "my-project"
  environment    = "production"
  logging_bucket = "my-logging-bucket"
}
```

## Contributing

Follow the [contributing guidelines][contributing] to contribute to this
repository.

[badge-release]: https://img.shields.io/github/v/release/codeforamerica/tofu-modules-aws-s3-bucket?logo=github&label=Latest%20Release
[contributing]: CONTRIBUTING.md
[kms]: #kms
[latest-release]: https://github.com/codeforamerica/tofu-modules-aws-s3-bucket/releases/latest
[malware-protection]: https://docs.aws.amazon.com/guardduty/latest/ug/malware-protection-s3.html
[malware_scanning]: #malware_scanning
[object-lock]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lock.html
[object_lock]: #object_lock
[storage-class]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/storage-class-intro.html
[storage_class_transitions]: #storage_class_transitions
[submodules]: #submodules
[uploads]: modules/uploads
