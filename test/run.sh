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

# Run the integration tests

# Deploy zookeeper
kubectl apply -f ${MANIFEST_DIR}/10-configs.yaml
kubectl apply -f ${MANIFEST_DIR}/11-zookeeper.yaml
kubectl rollout status statefulset/zk
sleep 60 # Let zk settle

# Test the deployment
kubectl apply -f ${MANIFEST_DIR}/20-test.yaml
wait_until_complete test-zk-3
kubectl delete -f ${MANIFEST_DIR}/20-test.yaml

kubectl rollout restart statefulset/zk
kubectl rollout status statefulset/zk
sleep 60 # zk settle

# Retest a restart of the cluster
kubectl apply -f ${MANIFEST_DIR}/20-test.yaml
wait_until_complete test-zk-3
kubectl delete -f ${MANIFEST_DIR}/20-test.yaml

# Expand the cluster to 5 nodes
kubectl apply -f ${MANIFEST_DIR}/30-configs.yaml
kubectl scale statefulset/zk --replicas 5
kubectl rollout status statefulset/zk
sleep 60 # zk settle

# Restest
kubectl apply -f ${MANIFEST_DIR}/50-test.yaml
wait_until_complete test-zk-5
kubectl delete -f ${MANIFEST_DIR}/50-test.yaml

# Cleanup
kubectl delete -f ${MANIFEST_DIR}/11-zookeeper.yaml
kubectl delete -f ${MANIFEST_DIR}/30-configs.yaml
