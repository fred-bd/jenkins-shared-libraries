#!/bin/bash

APPROLE_NAME="kubeauth"

# Get kubeconfig file
vault login -no-print $VAULT_TOKEN

approle_id=$(vault read auth/$APPROLE_NAME/role/configurer/role-id -format=json | jq -r .data.role_id)
secret_id=$(vault write -force auth/$APPROLE_NAME/role/configurer/secret-id -format=json | jq -r .data.secret_id)

kubectl create ns vault \
  --dry-run=client -o yaml | \
  kubectl apply -f -

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  annotations:
    replicator.v1.mittwald.de/replicate-to: "$NS_TO_REPLICATE"
  name: kubeauth-secrets
  namespace: vault
type: Opaque
stringData:
  approle-id: $approle_id
  secret-id: $approle_secret
EOF
