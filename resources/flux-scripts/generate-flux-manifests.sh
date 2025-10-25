#!/bin/bash

# Needed variables
# CLUSTER_CONFIG_REPOSITORY
# CLUSTER_CONFIG_PATH
# HELM_ARTIFACT_USER
# HELM_ARTIFACT_PASSWORD

manifests_base=flux-manifests
manifests_dir="$manifests_base/base"

mkdir -p $manifests_dir

# We don't need secrets since the repos are public
# ---------------------------------------------
# flux create secret git applications-repo-secret \
#   --url=ssh://${{ inputs.foundation-infra-repository }} \
#   --private-key-file=${{ inputs.foundation-infra-ssh-file }} \
#   --password=${{ inputs.foundation-infra-ssh-pass }} \
#   --export > $manifests_dir/foundation-infra-secret.yaml

# flux create secret git cluster-config-secret \
#   --url=ssh://${{ inputs.cluster-config-repository }} \
#   --private-key-file=${{ inputs.cluster-config-ssh-file }} \
#   --password=${{ inputs.cluster-config-ssh-pass }} \
#   --export > $manifests_dir/cluster-config-secret.yaml

# flux create source git flux-system \
#   --url=ssh://$CLUSTER_CONFIG_REPOSITORY \
#   --branch=main \
#   --secret-ref cluster-config-secret \
#   --export > $manifests_dir/gotk-sync.yaml

flux create source git flux-system \
  --url=$CLUSTER_CONFIG_REPOSITORY \
  --branch=main \
  --export > $manifests_dir/gotk-sync.yaml

flux create kustomization flux-system \
  --source=GitRepository/flux-system \
  --path="$CLUSTER_CONFIG_PATH" \
  --prune=true \
  --interval=10m \
  --export >> $manifests_dir/gotk-sync-ks.yaml

cat <<EOF > $manifests_dir/helm-repo-credentials.yaml
apiVersion: v1
stringData:
  username: $HELM_ARTIFACT_USER
  password: $HELM_ARTIFACT_PASSWORD
kind: Secret
metadata:
  name: helm-repo-credentials
  namespace: flux-system
EOF

files=$(ls $manifests_dir/*.yaml)

cat <<EOF > $manifests_dir/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
resources:
EOF

for file in $files; do
  echo "  - $(basename $file)" >> $manifests_dir/kustomization.yaml
done

kubectl kustomize $manifests_dir -o $manifests_dir/../flux-config.yaml

flux install \
  --export > $manifests_dir/../flux-deploy.yaml

# cat <<EOF > $manifests_dir/../kustomization.yaml
# apiVersion: kustomize.config.k8s.io/v1beta1
# resources:
# - flux-config.yaml
# - flux-deploy.yaml
# EOF

echo "$manifests_base"