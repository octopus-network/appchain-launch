# octoup

This module sets up multiple bootnodes for octopus network, but can also be used to deploy single validator. 

## Usage

**bootnodes**
```hcl
terraform apply -var-file=example-bootnodes.terraform.tfvars.json
```

**validator**
```hcl
terraform apply -var-file=example-validator.terraform.tfvars.json
```

## Providers

| Name | Version |
|------|---------|
| aws | n/a |
| random | n/a |


## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| chainspec\_url | | `string` | `""` | yes |
| chainspec\_checksum | | `string` | `""` | yes |
| bootnodes | | `list(string)` | `[]` | no |
| base\_image | | `string` | `""` | yes |
| start\_cmd | | `string` | `""` | no |
| keys\_octoup | | `string` | `""` | yes |
| cloud\_vendor | | `string` | `""` | yes |
| access\_key | | `string` | | yes |
| secret\_key | | `string` | | yes |

