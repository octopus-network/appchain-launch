# octopus-relayer

This module sets up relayer for octopus network in GKE (Google Kubernetes Engine).

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
| relays<br>- appchain_id<br>- appchain_endpoint<br>- anchor_contract_id<br>- relayer_private_key<br>- relayer_image<br>- start_block_height | | `map(object)`<br>- `string`<br>- `string`<br>- `string`<br>- `string`<br>- `string`<br>- `number` | | yes |
| near<br>- node_url<br>- wallet_url<br>- helper_url | | `object`<br>- `string`<br>- `string`<br>- `string` | | yes |
| project | The GCP project id | `string` | | yes |
| region | The location for regional resources | `string` | | yes |
| cluster | The name of the cluster | `string` | | yes |

