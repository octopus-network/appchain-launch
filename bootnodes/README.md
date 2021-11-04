# bootnodes

This module sets up multiple bootnodes for octopus network in GKE (Google Kubernetes Engine).

## Usage

```
terraform init
terraform apply
terraform destroy
```

## Providers

| Name | Version |
|------|---------|
| kubernetes | v2.4.1 |
| google | v3.80.0 |


## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| chain\_name | | `string` | | yes |
| bootnodes | The number of bootnodes | `number` | | yes |
| base\_image | | `string` | | yes |
| start\_cmd | | `string` | | yes |
| keys\_octoup | The relative path of the keys file [octokey](https://github.com/octopus-network/octokey) | `string` | | yes |
| project | The GCP project id | `string` | | yes |
| region | The location for regional resources | `string` | | yes |
| cluster | The name of the cluster | `string` | | yes |
