# octoup

This module sets up gateway and full node for octopus network in GKE (Google Kubernetes Engine).

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

### Gateway
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| gateway<br>- api_domains<br>- api_image<br>- messenger_image<br>- stat_image | | `object`<br>- `string`<br>- `string`<br>- `string`<br>- `string` | | yes |
| redis | | `object` | | yes |
| etcd<br>- hosts<br>- username<br>- password | | `object`<br>- `string`<br>- `string`<br>- `string` | | yes |
| kafka | | `object` | | yes |
| project | The GCP project id | `string` | | yes |
| region | The location for regional resources | `string` | | yes |
| cluster | The name of the cluster | `string` | | yes |

### Full Node
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| chains<br>- chainspec<br>- bootnodes<br>- image<br>- command<br>- replicas | | `map(object)`<br>- `string`<br>- `list(string)`<br>- `string`<br>- `string`<br>- `number` | | yes |
| etcd | | `object` | | yes |
| project | The GCP project id | `string` | | yes |
| region | The location for regional resources | `string` | | yes |
| cluster | The name of the cluster | `string` | | yes |
