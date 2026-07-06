# terraform-helloworld

Example Terraform module that generates a random pet name from a greeting.
Used to demonstrate the `terragrunt-aws-template` deployment pattern.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >=3.6 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_random"></a> [random](#provider\_random) | >=3.6 |

## Resources

| Name | Type |
| ---- | ---- |
| [random_pet.this](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/pet) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_addressee"></a> [addressee](#input\_addressee) | (Optional) Addressee utilized by random\_pet generator. Defaults to 'Mom'. | `string` | `"Mom"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_random_pet_greeting"></a> [random\_pet\_greeting](#output\_random\_pet\_greeting) | Random Pet Id |
<!-- END_TF_DOCS -->
