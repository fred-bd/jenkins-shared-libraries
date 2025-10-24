#!/bin/bash

# Needed variables
# FLUX_MANIFESTS_DIR

shard_dir="$FLUX_MANIFESTS_DIR/sharding"

mkdir -p $shard_dir

mv $FLUX_MANIFESTS_DIR/flux-deploy.yaml $shard_dir

cat <<EOF > $shard_dir/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
resources:
  - flux-deploy.yaml
nameSuffix: "-shard1"
commonAnnotations:
  sharding.fluxcd.io/role: "shard"
patches:
  - target:
      kind: (Namespace|CustomResourceDefinition|ClusterRole|ClusterRoleBinding|ServiceAccount|NetworkPolicy|ResourceQuota)
      labelSelector: "app.kubernetes.io/part-of=flux"
    patch: |
      apiVersion: v1
      kind: all
      metadata:
          name: all
      \$patch: delete
  - target:
      labelSelector: "app.kubernetes.io/component=notification-controller"
    patch: |
      apiVersion: v1
      kind: all
      metadata: 
        name: all
      \$patch: delete
  - target:
      kind: (Service|Deployment)
      name: (notification-controller|webhook-receiver)
    patch: |
      apiVersion: v1
      kind: all
      metadata: 
        name: all
      \$patch: delete
  - target:
      kind: Deployment
      name: (image-reflector-controller|image-automation-controller|fluxconfig-agent|fluxconfig-controller)
    patch: |
      apiVersion: v1
      kind: Deployment
      metadata:
        name: all
      \$patch: delete
  - target:
      kind: Service
      name: source-controller
    patch: |
      - op: replace
        path: /spec/selector/app
        value: source-controller-shard1
  - target:
      kind: Deployment
      name: source-controller
    patch: |
      - op: replace
        path: /spec/selector/matchLabels/app
        value: source-controller-shard1
      - op: replace
        path: /spec/template/metadata/labels/app
        value: source-controller-shard1
      - op: replace
        path: /spec/template/spec/containers/0/args/6
        value: --storage-adv-addr=source-controller-shard1.\$(RUNTIME_NAMESPACE).svc.cluster.local.
  - target:
      kind: Deployment
      name: kustomize-controller
    patch: |
      - op: replace
        path: /spec/selector/matchLabels/app
        value: kustomize-controller-shard1
      - op: replace
        path: /spec/template/metadata/labels/app
        value: kustomize-controller-shard1
  - target:
      kind: Deployment
      name: helm-controller
    patch: |
      - op: replace
        path: /spec/selector/matchLabels/app
        value: helm-controller-shard1
      - op: replace
        path: /spec/template/metadata/labels/app
        value: helm-controller-shard1
  - target:
      kind: Deployment
      name: (source-controller|kustomize-controller|helm-controller)
    patch: |
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --watch-label-selector=sharding.fluxcd.io/key=shard1
EOF

kubectl kustomize $shard_dir -o $shard_dir/flux-deploy-shard.yaml

cat <<EOF > $shard_dir/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
resources:
  - flux-deploy.yaml
  - flux-deploy-shard.yaml
patches:
  - target:
      kind: Deployment
      name: "(source-controller|kustomize-controller|helm-controller)"
      annotationSelector: "!sharding.fluxcd.io/role"
    patch: |
      - op: add
        path: /spec/template/spec/containers/0/args/0
        value: --watch-label-selector=!sharding.fluxcd.io/key
EOF

kubectl kustomize $shard_dir -o $FLUX_MANIFESTS_DIR/flux-deploy.yaml
