


export APP_INSTANCE_NAME=octopus
export NAMESPACE=default

export METRICS_EXPORTER_ENABLED=false

export TAG="3.4.9-20210502-144311"

export IMAGE_ETCD="marketplace.gcr.io/google/etcd"
export IMAGE_METRICS_EXPORTER="marketplace.gcr.io/google/etcd/prometheus-to-sd:${TAG}"

export ETCD_STORAGE_CLASS="premium-rwo"
export PERSISTENT_DISK_SIZE="1Gi"

export REPLICAS=3

export ETCD_ROOT_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 10 | head -n 1 | tr -d '\n')

export ETCD_ROOT_PASSWORD="VmYo8qJeCw"

kubectl create namespace "${NAMESPACE}"


helm template "${APP_INSTANCE_NAME}" chart/etcd \
  --namespace "${NAMESPACE}" \
  --set image.repo="${IMAGE_ETCD}" \
  --set image.tag="${TAG}" \
  --set persistence.storageClass="${ETCD_STORAGE_CLASS}" \
  --set persistence.size="${PERSISTENT_DISK_SIZE}" \
  --set metrics.image="${IMAGE_METRICS_EXPORTER}" \
  --set metrics.exporter.enabled="${METRICS_EXPORTER_ENABLED}" \
  --set auth.rbac.rootPassword="${ETCD_ROOT_PASSWORD}" \
  --set replicas="${REPLICAS}" \
  > "${APP_INSTANCE_NAME}_manifest.yaml"



kubectl get pods -o wide -l app.kubernetes.io/name=${APP_INSTANCE_NAME} --namespace "${NAMESPACE}"

# patch lb
kubectl patch svc "${APP_INSTANCE_NAME}-etcd" \
  --namespace "${NAMESPACE}" \
  --patch '{"spec": {"type": "LoadBalancer"}}'



# Get etcd root user password from secret object
ETCD_ROOT_PASSWORD=$(kubectl get secret --namespace "${NAMESPACE}" ${APP_INSTANCE_NAME}-etcd -o jsonpath="{.data.etcd-root-password}" | base64 --decode)
# user list
kubectl exec -it "${APP_INSTANCE_NAME}-etcd-0" --namespace "${NAMESPACE}" -- etcdctl --user root:${ETCD_ROOT_PASSWORD} user list

# member list
kubectl exec -it "${APP_INSTANCE_NAME}-etcd-0" --namespace "${NAMESPACE}" -- etcdctl --user root:${ETCD_ROOT_PASSWORD} member list

# endpoints
kubectl exec -it "${APP_INSTANCE_NAME}-etcd-0" --namespace "${NAMESPACE}" -- etcdctl --user root:${ETCD_ROOT_PASSWORD} \
    -w table --endpoints=octopus-etcd-0.octopus-etcd-headless.default.svc.cluster.local:2379,octopus-etcd-1.octopus-etcd-headless.default.svc.cluster.local:2379,octopus-etcd-2.octopus-etcd-headless.default.svc.cluster.local:2379 endpoint status

kubectl exec -it "${APP_INSTANCE_NAME}-etcd-0" --namespace "${NAMESPACE}" -- etcdctl --user root:${ETCD_ROOT_PASSWORD} \
    -w table endpoint status --cluster

kubectl exec -it "${APP_INSTANCE_NAME}-etcd-0" --namespace "${NAMESPACE}" -- etcdctl --user root:${ETCD_ROOT_PASSWORD} \
    -w table endpoint health --cluster


# port
kubectl port-forward svc/${APP_INSTANCE_NAME}-etcd --namespace "${NAMESPACE}" 2379
