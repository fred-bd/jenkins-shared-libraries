#!/bin/bash

# Get kubeconfig file
vault login $VAULT_TOKEN -no-print

vault kv get \
  -field=$SECRET_KEY \
  $KV_ENGINE_PATH > kube-config

echo "$PWD/kube-config"