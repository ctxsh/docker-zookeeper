#!/usr/bin/env bash
set -e

SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")
MANIFEST_DIR=${SCRIPT_DIR}/manifests

function wait_until_complete {
  echo "Waiting for test: $1"
  count=0
  while true; do
    succeeded=$(($(kubectl get job/$1 -o json | jq -r '.status.succeeded')))
    failed=$(($(kubectl get job/$1 -o json | jq -r '.status.failed')))
    if [ $failed -gt 0 ] ; then
      echo "Failed"
      exit 1
    fi

    if [ $succeeded -gt 0 ]; then
      echo "Succeeded"
      return 0
    fi

    if [ $count -gt 60 ] ; then
      echo "Timeout"
      exit 1
    fi

    count=$((count + 1))
    sleep 1
  done
}

# function kubectl_test {
#   kubectl apply -f $1
#   kubectl wait -f $1 --for condition=Succeeded
#   kubectl delete -f $1
#   kubectl wait -f $1 --for=delete
# }

# function kubectl apply -f {
#   kubectl apply -f $1
#   # kubectl wait -f $1 --for condition=Ready
# }

# function kubectl_apply {
#   kubectl apply -f $1
# }

# Run the integration tests

# Deploy zookeeper
kubectl apply -f ${MANIFEST_DIR}/10-configs.yaml
kubectl apply -f ${MANIFEST_DIR}/11-zookeeper.yaml

# Test the deployment
kubectl apply -f ${MANIFEST_DIR}/20-test.yaml
wait_until_complete test-zk-3
kubectl delete -f ${MANIFEST_DIR}/20-test.yaml

# Now modify the config to expand the cluster
kubectl apply -f ${MANIFEST_DIR}/30-configs.yaml
kubectl rollout restart statefulset/zk

# Retest
kubectl apply -f ${MANIFEST_DIR}/20-test.yaml
wait_until_complete test-zk-3
kubectl delete -f ${MANIFEST_DIR}/20-test.yaml

# Scale to the full 5 and test
kubectl scale statefulset/zk --replicas 5
kubectl apply -f ${MANIFEST_DIR}/50-test.yaml
wait_until_complete test-zk-5
kubectl delete -f ${MANIFEST_DIR}/50-test.yaml

