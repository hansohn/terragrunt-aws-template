<div align="center">
  <h3>terragrunt-aws-template</h3>
  <p>Terragrunt AWS Module Template Repository</p>
  <p>
    <!-- Build Status -->
    <a href="https://actions-badge.atrox.dev/hansohn/terragrunt-aws-template/goto?ref=main">
      <img src="https://img.shields.io/endpoint.svg?url=https%3A%2F%2Factions-badge.atrox.dev%2Fhansohn%2Fterragrunt-aws-template%2Fbadge%3Fref%3Dmain&style=for-the-badge">
    </a>
    <!-- Github Tag -->
    <a href="https://gitHub.com/hansohn/terragrunt-aws-template/tags/">
      <img src="https://img.shields.io/github/tag/hansohn/terragrunt-aws-template.svg?style=for-the-badge">
    </a>
    <!-- License -->
    <a href="https://github.com/hansohn/terragrunt-aws-template/blob/main/LICENSE">
      <img src="https://img.shields.io/github/license/hansohn/terragrunt-aws-template.svg?style=for-the-badge">
    </a>
    <!-- LinkedIn -->
    <a href="https://linkedin.com/in/ryanhansohn">
      <img src="https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555">
    </a>
  </p>
</div>

## :open_book: Usage

Welcome to the terragrunt-aws-template repo!

Deployments live under `deployments/<namespace>/<account>/<region>/<stack>`, and
that path is how Terragrunt locates each stack. Each account is bootstrapped by
[`aws-account-bootstrap`][bootstrap], which provisions the S3 backend, the
deploy/plan roles, and the `/org/tf/state-bucket` SSM parameter this template
reads. Authentication happens **before** Terragrunt runs — the runner is already
in the target account, so `terragrunt-common.hcl` resolves the account ID from
`aws sts get-caller-identity` and the backend bucket from SSM (no `assume_role`,
no org lookup).

### Local plans

Humans assume the read-only **`CodePlanRole`** via their SSO permission set, so
local plans match CI without apply rights. Configure a profile that chains SSO
into the plan role:

```ini
# ~/.aws/config
[profile sandbox-sso]
sso_session    = corp
sso_account_id = 111122223333
sso_role_name  = InfraDeveloper

[profile sandbox-plan]
role_arn       = arn:aws:iam::111122223333:role/Org/CodePlanRole
source_profile = sandbox-sso
```

```bash
aws sso login --profile sandbox-sso
AWS_PROFILE=sandbox-plan make dev        # container inherits the creds
# inside the container:
terragrunt plan                          # or: terragrunt run --all plan
```

Apply is blocked by IAM on this role — applies run in CI.

### CI (apply)

GitHub Actions authenticates via OIDC and assumes **`CodeDeployRole`** directly
(no central account, no role chaining):

```yaml
permissions:
  id-token: write        # required for OIDC
  contents: read
steps:
  - uses: aws-actions/configure-aws-credentials@v4
    with:
      role-to-assume: ${{ secrets.AWS_DEPLOY_ROLE_ARN }}
      aws-region: us-west-2
  # ... terragrunt run --all apply
```

Store the per-account `DeployRoleArn` (a stack output from the bootstrap seed)
as a GitHub **Environment** secret so each environment maps to its own account.

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

No providers.

## Modules

No modules.

## Resources

No resources.

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END_TF_DOCS -->

<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[bootstrap]: https://github.com/hansohn/aws-account-bootstrap
