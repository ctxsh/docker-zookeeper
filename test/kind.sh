#!/bin/bash
set -o errexit

SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")

reg_name='kind-registry'
reg_port='5000'
running="$(docker inspect -f '{{.State.Running}}' "${reg_name}" 2>/dev/null || true)"
if [ "${running}" != 'true' ]; then
  docker run \
    -d --restart=always -p "${reg_port}:5000" --name "${reg_name}" \
    registry:2
fi

cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."localhost:${reg_port}"]
    endpoint = ["http://${reg_name}:${reg_port}"]
nodes:
- role: control-plane
- role: worker
  extraMounts:
  - hostPath: .
    containerPath: /code
- role: worker
  extraMounts:
  - hostPath: .
    containerPath: /code
- role: worker
  extraMounts:
  - hostPath: .
    containerPath: /code
EOF

docker network connect "kind" "${reg_name}" || true

for node in $(kind get nodes); do
  kubectl annotate node "${node}" "kind.x-k8s.io/registry=localhost:${reg_port}" --overwrite=true;
done
