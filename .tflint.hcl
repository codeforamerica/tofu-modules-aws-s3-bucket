plugin "aws" {
  enabled = true
  version = "0.48.0"
  signature = "pgp"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

plugin "terraform" {
  preset = "all"
  enabled = true
}
