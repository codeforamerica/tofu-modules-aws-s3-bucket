# S3 Base Bucket Submodule

This submodule holds the bucket resources shared by the primary bucket and the
replica bucket in the [root module][root-module]: the bucket itself, public
access block, ownership controls, versioning, object lock, encryption,
lifecycle rule, bucket policy, and access logging.

It is internal to this repository. The root module computes the bucket name,
KMS key, and bucket policy and passes them in, so both buckets are built from
the same resources and can't drift apart. Use the [root module][root-module] or
the [uploads submodule][uploads] instead of calling this one directly.

[root-module]: ../../README.md
[uploads]: ../uploads
