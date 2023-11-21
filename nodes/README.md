# appchain-launch v2

## Prepare

- genesis.conf
- validator
  - priv_validator_key.json
  - node_id
  - node_key.json
- fullnode
  - node_id
  - node_key.json

## Validator

```bash
# apply
terraform apply -target=module.validator
# destroy
terraform destroy -target=module.validator
```

## Fullnode

```bash
# apply
terraform apply -target=module.fullnode
# destroy
terraform destroy -target=module.fullnode
```

## Outputs

```text
fullnode_gateway_service  = {
  grpc = "otto-9100-1-fullnode.gateway:9090"
  rpc  = "http://otto-9100-1-fullnode.gateway:8545"
  ws   = "ws://otto-9100-1-fullnode.gateway:8546"
}

fullnode_persistent_peers = [
  caf2c69f2c56804b5086ab455c4392a3ce4fc0f5@1.2.3.4:26656,
  c790a7236c3f4502dacb71f676f993303e518f57@4.3.2.1:26656,
]
```
