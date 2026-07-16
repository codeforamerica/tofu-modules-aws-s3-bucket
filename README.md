# AWS S3 Uploads Bucket Module

[![Main Checks][badge-checks]][code-checks] [![GitHub Release][badge-release]][latest-release]

This module creates an S3 bucket for file uploads. The bucket is configured with
logging, encryption, verisioning and a lifecycle configuration.

## Usage

Add this module to your `main.tf` (or appropriate) file and configure the inputs
to match your desired configuration. For example:

```hcl
module "module_name" {
  source = "github.com/codeforamerica/tofu-modules-aws-s3-uploads-bucket?ref=1.0.0"

  project        = "my-project"
  environment    = "development"
  logging-bucket = "my-logging-bucket"
  name           = "documents"
}
```

Make sure you re-run `tofu init` after adding the module to your configuration.

```bash
tofu init
tofu plan
```

To update the source for this module, pass `-upgrade` to `tofu init`:

```bash
tofu init -upgrade
```

## Inputs

| Name                                   | Description                                                                                                                                               | Type           | Default                                         | Required |
| -------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------- | ----------------------------------------------- | -------- |
| logging_bucket                         | S3 bucket to send access logs to.                                                                                                                         | `string`       | n/a                                             | yes      |
| name                                   | Name of the bucket. The project and environment will be prepended to this automatically.                                                                  | `string`       | n/a                                             | yes      |
| project                                | Project that these resources are supporting. This is used in the prefix to all resource names.                                                            | `string`       | n/a                                             | yes      |
| abort_incomplete_multipart_upload_days | Number of days to abort incomplete multipart uploads.                                                                                                     | `number`       | `7`                                             | no       |
| environment                            | The environment for the deployment. This is used in the prefix to all resource names.                                                                     | `string`       | `"development"`                                 | no       |
| force_delete                           | Whether to force delete the bucket and its contents. Must be set to `true` _and_ applied before the bucket can be deleted.                                | `bool`         | `false`                                         | no       |
| [kms]                                  | KMS encryption settings for the bucket.                                                                                                                    | `object`       | `{}`                                            | no       |
| noncurrent_version_expiration_days     | Number of days to expire noncurrent versions of objects.                                                                                                  | `number`       | `30`                                            | no       |
| [object_lock]                          | Object lock settings for the bucket.                                                                                                                       | `object`       | `{}`                                            | no       |
| [storage_class_transitions]            | List of storage class transitions to apply to the buckets lifecycle configuration.                                                                        | `list(object)` | `[{days  = 30, storage_class = "STANDARD_IA"}]` | no       |
| tags                                   | Optional tags to be applied to all resources.                                                                                                             | `map(string)`  | `{}`                                            | no       |

### kms

Configure how the bucket is encrypted with KMS. By default, the module creates a
new KMS key. To use an existing key instead, set `create` to `false` and provide
`encryption_key_arn`.

| Name               | Description                                                                                                                       | Type           | Default | Required |
| ------------------ | --------------------------------------------------------------------------------------------------------------------------------- | -------------- | ------- | -------- |
| allowed_principals | List of AWS principal ARNs to allow to use the KMS key, such as ECS task roles. Only applies when `create` is `true`.              | `list(string)` | `[]`    | no       |
| arn                | ARN of an existing KMS key to use for bucket encryption. Required when `create` is `false`.                                       | `string`       | `null`  | no       |
| create             | Whether to create a new KMS key for the bucket. When `false`, `arn` must be provided.                                             | `bool`         | `true`  | no       |
| recovery_period    | Number of days to recover the created KMS key after deletion. Must be between `7` and `30`. Only applies when `create` is `true`. | `number`       | `30`    | no       |

### object_lock

Configure [object lock][object-lock] to protect objects from being deleted or
overwritten. Object lock requires versioning, which this module always enables.
By default, a `GOVERNANCE` mode retention rule of 30 days is applied.

Object lock is enabled through the `aws_s3_bucket_object_lock_configuration`
resource, so it can be turned on for both new and existing buckets without
replacing them. To enable object lock without a default retention rule, set
`days` to `null`. Note that once object lock is enabled on a bucket, it cannot
be disabled.

| Name    | Description                                                                                                          | Type     | Default        | Required |
| ------- | ------------------------------------------------------------------------------------------------------------------ | -------- | -------------- | -------- |
| days    | Number of days for the default retention period. Set to `null` to enable object lock without a default retention rule. | `number` | `30`           | no       |
| enabled | Whether to enable object lock on the bucket. Can be enabled on an existing bucket, but cannot be disabled once enabled. | `bool`   | `true`         | no       |
| mode    | Default retention mode. Must be `GOVERNANCE` or `COMPLIANCE`. Only applies when `days` is set.                      | `string` | `"GOVERNANCE"` | no       |

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

| Name               | Description                                                                     | Type     |
| ------------------ | ------------------------------------------------------------------------------- | -------- |
| bucket_name        | Name of the created bucket.                                                     | `string` |
| bucket_arn         | Full ARN of the created bucket.                                                 | `string` |
| bucket_domain_name | Domain name of the created bucket, in the format `bucketname.s3.amazonaws.com`. | `string` |
| kms_key_arn        | ARN of the KMS key used for bucket encryption.                                  | `string` |

## Contributing

Follow the [contributing guidelines][contributing] to contribute to this
repository.

[badge-checks]: https://github.com/codeforamerica/tofu-modules-aws-s3-uploads-bucket/actions/workflows/main.yaml/badge.svg
[badge-release]: https://img.shields.io/github/v/release/codeforamerica/tofu-modules-aws-s3-uploads-bucket?logo=github&label=Latest%20Release
[code-checks]: https://github.com/codeforamerica/tofu-modules-aws-s3-uploads-bucket/actions/workflows/main.yaml
[contributing]: CONTRIBUTING.md
[kms]: #kms
[latest-release]: https://github.com/codeforamerica/tofu-modules-aws-s3-uploads-bucket/releases/latest
[object-lock]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lock.html
[object_lock]: #object_lock
[storage-class]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/storage-class-intro.html
[storage_class_transitions]: #storage_class_transitions
