#!/bin/bash

# Creating the required policies to work with certificates

auth='auth-manager'
issuer='issuer-manager'
policy='policy-manager'

cat <<EOF | vault policy write $auth - > /dev/null 2>&1
path "sys/auth/*" { capabilities = ["create", "update", "sudo"] }
path "sys/auth"   { capabilities = ["read"] }
path "auth/*"     { capabilities = [ "update", "create" ] }
EOF

cat <<EOF | vault policy write $policy - > /dev/null 2>&1
path "sys/policies/*" { capabilities = [ "create", "update", "read", "list" ] }
EOF

cat <<EOF | vault policy write $issuer - > /dev/null 2>&1
path "sys/mounts/*" { capabilities = [ "create", "read", "update", "delete", "list" ] }
path "sys/mounts" { capabilities = [ "read", "list" ] }
path "pki*" { capabilities = [ "create", "read", "update", "delete", "list", "sudo", "patch" ] }
EOF

echo "$auth,$issuer,$policy"