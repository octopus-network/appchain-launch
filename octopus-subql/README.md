# octopus-subql

This module sets up subql for octopus network in GKE (Google Kubernetes Engine).

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
| subql<br>- appchain_id<br>- appchain_endpoint<br>- gce_proxy_image<br>- gce_proxy_instances<br>- subql_node_image<br>- subql_query_image | | `map(object)`<br>- `string`<br>- `string`<br>- `string`<br>- `string`<br>- `string`<br>- `string` | | yes |
| database<br>- username<br>- password<br>- database | | `object`<br>- `string`<br>- `string`<br>- `string` | | yes |
| service_account | Service account for cloud sql | `string` | | yes |
| project | The GCP project id | `string` | | yes |
| region | The location for regional resources | `string` | | yes |
| cluster | The name of the cluster | `string` | | yes |

