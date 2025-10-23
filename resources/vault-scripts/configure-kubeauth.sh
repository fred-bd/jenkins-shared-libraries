#!/bin/bash

# Configuring a approle to be used by kubeauth jobs
APPROLE_NAME="kubeauth"
APPROLE_EXISTS=$(vault auth list | grep "$APPROLE_NAME" || true)

if [ -z "$APPROLE_EXISTS" ]; then
  vault auth enable --no-print -path="$APPROLE_NAME" approle
else
  echo "!!$APPROLE_NAME already exists!!"
fi

policies="$POLICIES"

vault write auth/$APPROLE_NAME/role/configurer --no-print \
  token_policies=$policies \
  secret_id_ttl=0 \
  token_num_uses=0 \
  token_ttl=4h \
  token_max_ttl=8h \
  secret_id_num_uses=0

approle_id=$(vault read auth/$APPROLE_NAME/role/configurer/role-id -format=json | jq -r .data.role_id)
secret_id=$(vault write --no-print -force auth/$APPROLE_NAME/role/configurer/secret-id -format=json | jq -r .data.secret_id)

echo "id=$approle_id,secret=$secret_id" 
