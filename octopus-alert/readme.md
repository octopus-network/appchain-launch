# Migration

## Create configmap & secret
`terraform apply -target="kubernetes_secret.default" -target="kubernetes_config_map.default"`

## Import deployment
`terraform import kubernetes_deployment.default default/octopus-alert`
