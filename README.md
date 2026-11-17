<div align="center">
  <h1>terragrunt-aws-template</h1>
  <p>Terragrunt AWS template repository with CI plan/apply, OIDC authentication and a Docker-based dev environment.</p>
  <p>
    <!-- CI -->
    <a href="https://github.com/hansohn/terragrunt-aws-template/actions/workflows/ci.yml"><img alt="CI" src="https://img.shields.io/github/actions/workflow/status/hansohn/terragrunt-aws-template/ci.yml?branch=main&label=CI&style=for-the-badge"></a>
    <!-- Tag -->
    <a href="https://github.com/hansohn/terragrunt-aws-template/tags"><img alt="Tag" src="https://img.shields.io/github/v/tag/hansohn/terragrunt-aws-template?sort=semver&style=for-the-badge"></a>
    <!-- License -->
    <a href="LICENSE"><img alt="License" src="https://img.shields.io/github/license/hansohn/terragrunt-aws-template?style=for-the-badge"></a>
  </p>
  <p>
    <a href="#quick-start">Quick Start</a> •
    <a href="#usage">Usage</a> •
    <a href="#development">Development</a> •
    <a href="#contributing">Contributing</a>
  </p>
</div>

## Overview

A starting point for Terragrunt stacks on AWS. Stacks live under
`deployments/<account>/<region>/<stack>`, share one
`root.hcl`, and deploy from GitHub Actions without long-lived credentials.

## Highlights

- **Path-driven stacks** // The `deployments/<account>/<region>/<stack>` path sets the region and stack name; CI picks the account from `ACCOUNT_LABEL`
- **OIDC deploys** // GitHub Actions assumes a hub runner role, then chains into the account's deploy role
- **Tag-as-approval** // Branch pushes plan; pushing `vX.Y.Z` applies
- **Local plans** // `make dev` opens a container with the same tooling as CI
- **Repo hygiene** // yamllint, actionlint and zizmor in CI, Conventional Commit PR titles

## Prerequisites

- Make, Git and Docker
- AWS CLI with SSO access to the target account
- [yamllint](https://yamllint.readthedocs.io/), [actionlint](https://github.com/rhysd/actionlint) and [zizmor](https://docs.zizmor.sh/) for `make lint`

## Quick Start

```bash
gh repo create hansohn/<name> --template hansohn/terragrunt-aws-template --private --clone
```

Then set the `RUNNER_ROLE_ARN` and `ORG_PREFIX` repository variables
(Settings > Secrets and variables > Actions > Variables). Update `ACCOUNT_LABEL`
in `.github/workflows/terragrunt.yml`. Add the `SLACK_WEBHOOK`, `SLACK_CHANNEL_ID` and
`SLACK_USERNAME` secrets, which the `slack` job needs.

## Usage

Deployments live under `deployments/<account>/<region>/<stack>`, and
that path is how Terragrunt locates each stack. Each account is bootstrapped by
[`aws-account-bootstrap`][bootstrap], which provisions the S3 backend, the
deploy/plan roles, and the `/org/tf/state-bucket` SSM parameter this template
reads. Authentication happens **before** Terragrunt runs — the runner is already
in the target account, so `root.hcl` resolves the account ID from
`aws sts get-caller-identity` and the backend bucket from SSM (no `assume_role`,
no org lookup).

Account-wide resources such as IAM go in `deployments/<account>/_global/<stack>`.
The `_global` stacks use the region in `GLOBAL_REGION` (default `us-west-2`). Any
other directory in the region position must be an AWS region name, or the run fails.

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

### CI

`.github/workflows/terragrunt.yml` runs format, lint and plan on every branch push.
Pushing a `vX.Y.Z` tag applies. Authentication is handled by
`.github/actions/aws-auth`: OIDC into the hub `TerraformRunnerRole`, then
role-chaining into the target account's `TerraformDeploymentRole`.

## Development

```bash
make help    # list targets
make lint    # run yamllint, actionlint and zizmor
make dev     # open the local dev container
```

## Security

To report a vulnerability, see the [Security Policy](https://github.com/hansohn/.github/blob/HEAD/SECURITY.md).
Do not open a public issue.

## Contributing

Contributions are welcome. See the [Contributing Guide](https://github.com/hansohn/.github/blob/HEAD/CONTRIBUTING.md)
for the full workflow.

- Report bugs via [Bug Reports](https://github.com/hansohn/terragrunt-aws-template/issues/new?template=bug-report.yml)
- Request features via [Feature Requests](https://github.com/hansohn/terragrunt-aws-template/issues/new?template=feature-request.yml)
- Follow the [Code of Conduct](https://github.com/hansohn/.github/blob/HEAD/CODE_OF_CONDUCT.md)

## License

Apache 2.0. See [LICENSE](LICENSE).

[bootstrap]: https://github.com/hansohn/aws-account-bootstrap
