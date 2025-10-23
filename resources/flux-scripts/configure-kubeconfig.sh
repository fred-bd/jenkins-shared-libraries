#!/bin/bash

# Get kubeconfig file
vault login $VAULT_TOKEN

vault kv get \
  -field=$SECRET_KEY \
  $KV_ENGINE_PATH > kube-config

echo "Trying to access kubernetes"

kubectl get ns --kubeconfig kube-config
