#!/bin/bash

# Get kubeconfig file
vault login -no-print $VAULT_TOKEN

vault kv get \
  -field=$SECRET_KEY \
  $KV_ENGINE_PATH > kube-config

echo "$PWD/kube-config"