#!/usr/bin/env bash

SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")
MANIFEST_DIR=${SCRIPT_DIR}/manifests

for m in $(ls -r ${MANIFEST_DIR}); do
  kubectl delete -f ${MANIFEST_DIR}/${m}
done