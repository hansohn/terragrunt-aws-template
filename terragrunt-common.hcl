locals {
  # Determine deployment location based on the repo path:
  #   "<namespace>/<aws_account_name>/<aws_region>/<deployment_name>"

  relative_path     = path_relative_to_include()
  relative_path_lst = split("/", local.relative_path)

  namespace        = element(local.relative_path_lst, 0)
  aws_account_name = element(local.relative_path_lst, 1)
  aws_region_raw   = element(local.relative_path_lst, 2)
  deployment_name  = element(local.relative_path_lst, 3)

  aws_region         = length(regexall("^([a-z]{2}(?:-gov){0,1}-(?:central|east|north|south|west){1,2}-\\d)$", local.aws_region_raw)) > 0 ? local.aws_region_raw : local.default_aws_region
  default_aws_region = get_env("AWS_DEFAULT_REGION", "us-west-2")
  repo_name          = get_env("REPO_NAME", "unknown")

  # Region where the Terraform state bucket and its SSM registration live.
  state_region = get_env("TF_STATE_REGION", "us-west-2")

  # The runner is already authenticated into the target account (GitHub OIDC in
  # CI, an assume-role profile locally), so read identity and the backend bucket
  # from the account itself — no org-wide lookup, nothing to leak. The bucket
  # name is published by the account-bootstrap seed at /org/tf/state-bucket.
  aws_account_id = run_cmd("--terragrunt-quiet", "aws", "sts", "get-caller-identity", "--query", "Account", "--output", "text")
  state_bucket   = run_cmd("--terragrunt-quiet", "aws", "ssm", "get-parameter", "--region", local.state_region, "--name", "/org/tf/state-bucket", "--query", "Parameter.Value", "--output", "text")
}

generate "backend" {
  path      = "auto-backend.tf"
  if_exists = "overwrite_terragrunt"

  contents = <<-EOF
    terraform {
      backend "s3" {
        bucket       = "${local.state_bucket}"
        key          = "${local.repo_name}/${local.relative_path}/terraform.tfstate"
        region       = "${local.state_region}"
        use_lockfile = true
        encrypt      = true
      }
    }
  EOF
}

generate "provider" {
  path      = "auto-provider.tf"
  if_exists = "overwrite_terragrunt"

  contents = <<-EOF
    provider "aws" {
      region = "${local.aws_region}"

      default_tags {
        tags = {
          "Repo"            = "${local.repo_name}"
          "terraform:state" = "s3://${local.state_bucket}/${local.repo_name}/${local.relative_path}/terraform.tfstate"
        }
      }
    }
  EOF
}

terraform {
  extra_arguments "output" {
    commands  = ["plan"]
    arguments = ["-out", "terraform.plan"]
  }
}
