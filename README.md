# AWS S3 Uploads Bucket Module

[![GitHub Release][badge-release]][latest-release]

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

### Malware protection

When `enable_malware_protection` is set to `true` (the default), the module will
create a [GuardDuty Malware Protection][guardduty-malware] plan, along with the
neccassry IAM role for it to access the created bucket.

When new objects are uploaded to the bucket, they will be tagged with
`GuardDutyMalwareScanStatus` which can have one of the following values:
`ACCESS_DENIED`, `FAILED`, `NO_THREATS_FOUND`, `THREATS_FOUND`, and
`UNSUPPORTED`. For more information on what these values mean, see the
[documentation on potential scan status][scan-statuses].

You can use [Amazon EventBridge rules][malware-eventbridge] to respond
appropraitly to different scan results.

## Inputs

| Name                                   | Description                                                                                                                                               | Type           | Default                                         | Required |
| -------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------- | ----------------------------------------------- | -------- |
| logging_bucket                         | S3 bucket to send access logs to.                                                                                                                         | `string`       | n/a                                             | yes      |
| name                                   | Name of the bucket. The project and environment will be prepended to this automatically.                                                                  | `string`       | n/a                                             | yes      |
| project                                | Project that these resources are supporting. This is used in the prefix to all resource names.                                                            | `string`       | n/a                                             | yes      |
| abort_incomplete_multipart_upload_days | Number of days to abort incomplete multipart uploads.                                                                                                     | `number`       | `7`                                             | no       |
| allowed_principals                     | List of AWS principal ARNs to allow to use the KMS key. This is used to grant access to other resources that need to use the key, such as ECS task roles. | `list(string)` | `[]`                                            | no       |
| enable_malware_protection              | Whether to enable malware protection for the bucket using GuardDuty. This will create a new IAM role and GuardDuty malware protection plan.               | `bool`         | `true`                                          | no       |
| encryption_key_arn                     | ARN of the KMS key to use for S3 bucket encryption. If not provided, a new KMS key will be created.                                                       | `string`       | `null`                                          | no       |
| environment                            | The environment for the deployment. This is used in the prefix to all resource names.                                                                     | `string`       | `"development"`                                 | no       |
| force_delete                           | Whether to force delete the bucket and its contents. Must be set to `true` _and_ applied before the bucket can be deleted.                                | `bool`         | `false`                                         | no       |
| key_recovery_period                    | Number of days to recover the created KMS key after deletion. Must be between `7` and `30`.                                                               | `number`       | `30`                                            | no       |
| noncurrent_version_expiration_days     | Number of days to expire noncurrent versions of objects.                                                                                                  | `number`       | `30`                                            | no       |
| [storage_class_transitions]            | List of storage class transitions to apply to the buckets lifecycle configuration.                                                                        | `list(object)` | `[{days  = 30, storage_class = "STANDARD_IA"}]` | no       |
| tags                                   | Optional tags to be applied to all resources.                                                                                                             | `map(string)`  | `{}`                                            | no       |

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

| Name                        | Description                                                                     | Type     |
| --------------------------- | ------------------------------------------------------------------------------- | -------- |
| bucket_name                 | Name of the created bucket.                                                     | `string` |
| bucket_arn                  | Full ARN of the created bucket.                                                 | `string` |
| bucket_domain_name          | Domain name of the created bucket, in the format `bucketname.s3.amazonaws.com`. | `string` |
| kms_key_arn                 | ARN of the KMS key used for bucket encryption.                                  | `string` |
| malware_protection_plan_arn | ARN of the GuardDuty malware protection plan, if malware protection is enabled. | `string` |

## Contributing

Follow the [contributing guidelines][contributing] to contribute to this
repository.

[badge-release]: https://img.shields.io/github/v/release/codeforamerica/tofu-modules-aws-s3-uploads-bucket?logo=github&label=Latest%20Release
[contributing]: CONTRIBUTING.md
[guardduty-malware]: https://docs.aws.amazon.com/guardduty/latest/ug/configuring-malware-protection-for-s3-guardduty.html
[latest-release]: https://github.com/codeforamerica/tofu-modules-aws-s3-uploads-bucket/releases/latest
[malware-eventbridge]: https://docs.aws.amazon.com/guardduty/latest/ug/monitor-with-eventbridge-s3-malware-protection.html
[scan-statuses]: https://docs.aws.amazon.com/guardduty/latest/ug/monitoring-malware-protection-s3-scans-gdu.html#s3-object-scan-result-value-malware-protection
[storage-class]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/storage-class-intro.html
[storage_class_transitions]: #storage_class_transitions
