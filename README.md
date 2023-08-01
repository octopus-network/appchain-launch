# appchain-launch v2

## Prepare

- genesis.conf
- validator
  - mnemonic
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
