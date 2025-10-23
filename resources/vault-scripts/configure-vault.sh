#!/bin/bash

name: Configure Vault
description: 'Configure vault accesses'
inputs:
  renew_ca:
    description: 'To renew the root ca'
    required: true
  common_name:
    description: 'Common name to be used for the certificate (domain)'
    required: true
outputs:
  kubeauth_approle_id:
    description: The approle id for the issuer
    value: ${{ steps.configure-approle-kubeauth.outputs.kubeapprole_id }}
  kubeauth_secret_id:   
    description: The approle secret id for the issuer
    value: ${{ steps.configure-approle-kubeauth.outputs.kubesecret_id }}
  flux_approle_id:
    description: The approle id for the flux reader
    value: ${{ steps.configure-approle-flux.outputs.fluxapprole_id }}
  flux_secret_id:
    description: The approle secret id for the flux reader
    value: ${{ steps.configure-approle-flux.outputs.fluxsecret_id }}
runs:
  using: 'composite'
  steps:
    # - name: Configure kube-auth jobs policies
    #   shell: sh
    #   id: kubeauth-policies
    #   run: |
    #     auth='auth-manager'
    #     issuer='issuer-manager'
    #     policy='policy-manager'

    #     cat <<EOF | vault policy write $auth -
    #     path "sys/auth/*" { capabilities = ["create", "update", "sudo"] }
    #     path "sys/auth"   { capabilities = ["read"] }
    #     path "auth/*"     { capabilities = [ "update", "create" ] }
    #     EOF

    #     cat <<EOF | vault policy write $policy -
    #     path "sys/policies/*" { capabilities = [ "create", "update", "read", "list" ] }
    #     EOF

    #     cat <<EOF | vault policy write $issuer -
    #     path "sys/mounts/*" { capabilities = [ "create", "read", "update", "delete", "list" ] }
    #     path "sys/mounts" { capabilities = [ "read", "list" ] }
    #     path "pki*" { capabilities = [ "create", "read", "update", "delete", "list", "sudo", "patch" ] }
    #     EOF

    #     echo "policies=$auth,$issuer,$policy" >> $GITHUB_OUTPUT

    - name: Configure kubeauth approle for access from kubeauth jobs
      shell: sh
      id: configure-approle-kubeauth
      run: |
        # APPROLE_NAME="kubeauth"
        # APPROLE_EXISTS=$(vault auth list | grep "$APPROLE_NAME" || true)

        # if [ -z "$APPROLE_EXISTS" ]; then
        #   vault auth enable -path="$APPROLE_NAME" approle
        # else
        #   echo "!!$APPROLE_NAME already exists!!"
        # fi

        # policies="${{ steps.kubeauth-policies.outputs.policies }}"

        # vault write auth/$APPROLE_NAME/role/configurer \
        #   token_policies=$policies \
        #   secret_id_ttl=0 \
        #   token_num_uses=0 \
        #   token_ttl=4h \
        #   token_max_ttl=8h \
        #   secret_id_num_uses=0

        # approle_id=$(vault read auth/$APPROLE_NAME/role/configurer/role-id -format=json | jq -r .data.role_id)
        # secret_id=$(vault write -force auth/$APPROLE_NAME/role/configurer/secret-id -format=json | jq -r .data.secret_id)

        # echo "::add-mask::$secret_id"

        # echo "kubeapprole_id=$approle_id" >> $GITHUB_OUTPUT
        # echo "kubesecret_id=$secret_id" >> $GITHUB_OUTPUT

    - shell: sh
      name: Configure vault issuer certificate Root CA
      id: configure-issuer-ca
      run: |
    #     PKI_NAME="$(echo ${{ inputs.common_name }} | sed 's/\./-/g')"
        
    #     SECRET_EXISTS=$(vault secrets list | grep "bede-apps-com" || true)

    #     if [ -z "$SECRET_EXISTS" ]; then
    #       vault secrets enable -path $PKI_NAME pki
    #       vault secrets tune -max-lease-ttl=87600h $PKI_NAME
    #     else
    #       echo "!!$PKI_NAME already exists!!"
    #     fi

    #     now=$(date +'%Y%m%d-%H%M%S')
    #     issuer_name="root-ca-$now"

    #     vault write -field=certificate $PKI_NAME/root/generate/internal \
    #       common_name=${{ inputs.common_name }} \
    #       issuer_name="$issuer_name" \
    #       ttl=87600h > $TEMP_JOB_DIR/$issuer_name.crt

    #     vault write $PKI_NAME/config/urls \
    #       issuing_certificates="$VAULT_ADDR/v1/$PKI_NAME/ca" \
    #       crl_distribution_points="$VAULT_ADDR/v1/$PKI_NAME/crl"

    #     vault write $PKI_NAME/roles/$PKI_NAME-dot-com-root \
    #      allow_any_name=true

    #     echo "root_ca=$TEMP_JOB_DIR/$issuer_name.crt" >> $GITHUB_OUTPUT
    #     echo "root_sign_address=$PKI_NAME/root" >> $GITHUB_OUTPUT
    #     echo "root_ca_date=$now" >> $GITHUB_OUTPUT
    #     echo "root_issuer_name=$issuer_name" >> $GITHUB_OUTPUT

    # - shell: sh
    #   name: Configure vault issuer certificate intermediate
    #   run: |
    #     PKI_NAME="$(echo ${{ inputs.common_name }} | sed 's/\./-/g')_intermediate"

    #     root_sign_address=${{ steps.configure-issuer-ca.outputs.root_sign_address }}
    #     root_issuer_name=${{ steps.configure-issuer-ca.outputs.root_issuer_name }}
    #     root_issuer_date=${{ steps.configure-issuer-ca.outputs.root_ca_date }}
        
    #     SECRET_EXISTS=$(vault secrets list | grep "$PKI_NAME" || true)

    #     if [ -z "$SECRET_EXISTS" ]; then
    #       vault secrets enable -path $PKI_NAME pki
    #       vault secrets tune -max-lease-ttl=43800h $PKI_NAME
    #     else
    #       echo "!!$PKI_NAME already exists!!"
    #     fi

    #     vault write -format=json $PKI_NAME/intermediate/generate/internal \
    #       common_name="${{ inputs.common_name }} Intermediate Authority" \
    #       issuer_name="$PKI_NAME"-intermediate-$root_ca_date \
    #       | jq -r '.data.csr' > $TEMP_JOB_DIR/intermediate.csr

    #     vault write -format=json $root_sign_address/sign-intermediate \
    #       issuer_ref="$root_issuer_name" \
    #       csr=@$TEMP_JOB_DIR/intermediate.csr \
    #       format=pem_bundle ttl="43800h" \
    #       | jq -r '.data.certificate' > $TEMP_JOB_DIR/intermediate.cert.pem

    #     vault write $PKI_NAME/intermediate/set-signed \
    #       certificate=@$TEMP_JOB_DIR/intermediate.cert.pem

    #     vault write $PKI_NAME/roles/$PKI_NAME-dot-com \
    #       issuer_ref="$(vault read -field=default $PKI_NAME/config/issuers)" \
    #       allowed_domains="${{ inputs.common_name }}" \
    #       allow_bare_domains=true \
    #       allow_subdomains=true \
    #       require_cn=false \
    #       max_ttl=72h

    - shell: sh
      name: Configure flux-reader
      id: configure-approle-flux
      run: |
        APPROLE_NAME="flux"
        APPROLE_EXISTS=$(vault auth list | grep "$APPROLE_NAME" || true)
        ROLE_POLICY=$APPROLE_NAME"-read"
        READER_POLICY=$APPROLE_NAME"-reader"

        if [ -z "$APPROLE_EXISTS" ]; then
          vault auth enable -path="$APPROLE_NAME" approle
        else
          echo "!!$APPROLE_NAME already exists!!"
        fi

        cat <<EOF | vault policy write $ROLE_POLICY -
        path "cluster-hosts/*" { capabilities = [ "read", "list" ] }
        path "github-access/*" { capabilities = [ "read", "list" ] }
        path "helm-repo-credentials/*" { capabilities = [ "read", "list" ] }
        EOF

        vault write auth/$APPROLE_NAME/role/$READER_POLICY \
          token_policies=$ROLE_POLICY \
          secret_id_ttl=0 \
          token_num_uses=0 \
          token_ttl=4h \
          token_max_ttl=8h \
          secret_id_num_uses=0

        approle_id=$(vault read auth/$APPROLE_NAME/role/$READER_POLICY/role-id -format=json | jq -r .data.role_id)
        secret_id=$(vault write -force auth/$APPROLE_NAME/role/$READER_POLICY/secret-id -format=json | jq -r .data.secret_id)

        echo "::add-mask::$secret_id"

        echo "fluxapprole_id=$approle_id" >> $GITHUB_OUTPUT
        echo "fluxsecret_id=$secret_id" >> $GITHUB_OUTPUT
