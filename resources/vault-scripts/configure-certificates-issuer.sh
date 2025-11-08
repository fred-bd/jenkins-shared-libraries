#!/bin/bash

# Configure vault issuer certificate Root CA
PKI_NAME="$(echo $COMMON_NAME | sed 's/\./-/g')"
SECRET_EXISTS=$(vault secrets list | grep "$PKI_NAME" || true)

if [ -z "$SECRET_EXISTS" ]; then
  vault secrets enable -path $PKI_NAME pki
  vault secrets tune -max-lease-ttl=87600h $PKI_NAME
else
  echo "!!$PKI_NAME already exists!!"
fi

now=$(date +'%Y%m%d-%H%M%S')
issuer_name="root-ca-$now"

vault write -field=certificate $PKI_NAME/root/generate/internal \
  common_name=$COMMON_NAME \
  issuer_name="$issuer_name" \
  ttl=87600h > $issuer_name.crt

vault write $PKI_NAME/config/urls \
  issuing_certificates="$VAULT_ADDR/v1/$PKI_NAME/ca" \
  crl_distribution_points="$VAULT_ADDR/v1/$PKI_NAME/crl"

vault write $PKI_NAME/roles/$PKI_NAME-dot-com-root \
  allow_any_name=true

# Configure vault issuer certificate intermediate
PKI_NAME_I="$(echo $COMMON_NAME | sed 's/\./-/g')_intermediate"

root_sign_address=$PKI_NAME/root
root_issuer_name=$issuer_name
root_issuer_date=$now

SECRET_EXISTS=$(vault secrets list | grep "$PKI_NAME_I" || true)

if [ -z "$SECRET_EXISTS" ]; then
  vault secrets enable -path $PKI_NAME_I pki
  vault secrets tune -max-lease-ttl=43800h $PKI_NAME_I
else
  echo "!!$PKI_NAME_I already exists!!"
fi

vault write -format=json $PKI_NAME_I/intermediate/generate/internal \
  common_name="$COMMON_NAME Intermediate Authority" \
  issuer_name="$PKI_NAME_I"-intermediate-$root_ca_date \
  | jq -r '.data.csr' > intermediate.csr

vault write -format=json $root_sign_address/sign-intermediate \
  issuer_ref="$root_issuer_name" \
  csr=@intermediate.csr \
  format=pem_bundle ttl="43800h" \
  | jq -r '.data.certificate' > intermediate.cert.pem

vault write $PKI_NAME_I/intermediate/set-signed \
  certificate=@intermediate.cert.pem

vault write $PKI_NAME_I/roles/$PKI_NAME_I-dot-com \
  issuer_ref="$(vault read -field=default $PKI_NAME_I/config/issuers)" \
  allowed_domains="$COMMON_NAME" \
  allow_bare_domains=true \
  allow_subdomains=true \
  require_cn=false \
  max_ttl=72h