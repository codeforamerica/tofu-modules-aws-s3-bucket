# S3 Uploads Bucket Submodule

This submodule creates an S3 bucket for file uploads. It wraps the [root S3
bucket module][root-module] with opinionated defaults suited to buckets that
receive user-uploaded files, so an uploads bucket meets our requirements without
additional configuration.

The following behavior is **enforced** and cannot be disabled through this
submodule:

- **Malware scanning is always enabled.** Uploaded objects are scanned by
  GuardDuty Malware Protection for S3 as they arrive. If you need a bucket
  without malware scanning, use the [root module][root-module] directly.
- **Scan results are always tagged onto objects** (`GuardDutyMalwareScanStatus`)
  so they can be acted on per object.

All other settings use upload-appropriate defaults and can be overridden. In
particular:

- `name` defaults to `uploads`.
- `malware_scanning.restrict_access` defaults to `true`, so unscanned or
  infected objects are not served. Set it to `false` if your application needs
  to read objects before they are scanned, or must serve files GuardDuty cannot
  scan (for example, files too large to scan, tagged `UNSUPPORTED`).

## Usage

```hcl
module "uploads" {
  source = "github.com/codeforamerica/tofu-modules-aws-s3-bucket//modules/uploads?ref=1.0.0"

  project        = "my-project"
  environment    = "production"
  logging_bucket = "my-logging-bucket"
}
```

## Inputs

This submodule accepts the same inputs as the [root module][root-module], with
these differences:

| Name             | Description                                                                                                                        | Type     | Default     | Required |
| ---------------- | ---------------------------------------------------------------------------------------------------------------------------------- | -------- | ----------- | -------- |
| name             | Name of the bucket. The project and environment will be prepended to this automatically.                                           | `string` | `"uploads"` | no       |
| malware_scanning | Malware scanning settings. Scanning and result tagging are always enabled; `enabled` and `tag_objects` are not exposed. See below. | `object` | `{}`        | no       |

### malware_scanning

| Name            | Description                                                                                                                                          | Type           | Default | Required |
| --------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- | -------------- | ------- | -------- |
| object_prefixes | List of object key prefixes to scan. When empty, all objects in the bucket are scanned.                                                              | `list(string)` | `[]`    | no       |
| restrict_access | Whether to deny `s3:GetObject` for objects not tagged `GuardDutyMalwareScanStatus = NO_THREATS_FOUND`. Also blocks objects GuardDuty could not scan. | `bool`         | `true`  | no       |

## Outputs

| Name                      | Description                                            | Type     |
| ------------------------- | ------------------------------------------------------ | -------- |
| arn                       | Full ARN of the created bucket.                        | `string` |
| domain_name               | Domain name of the created bucket.                     | `string` |
| kms_key_arn               | ARN of the KMS key used for bucket encryption.         | `string` |
| malware_scanning_role_arn | ARN of the IAM role GuardDuty assumes to scan objects. | `string` |
| name                      | Name of the created bucket.                            | `string` |

[root-module]: ../../README.md
