locals {
  logs_path = "/AWSLogs/${data.aws_caller_identity.identity.account_id}"
}
