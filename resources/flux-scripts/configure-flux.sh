name: 'Deploy Flux'
description: 'Deploys Flux controller manifests'
inputs:
  flux-config:
    description: 'The Flux configuration'
  flux-deploy:
    description: 'The Flux deployment'
  clean-deployment:
    description: 'Clean the deployment'
  install-flux:
    description: 'Install Flux'
    default: 'true'

runs:
  using: 'composite'
  steps:
    - name: Clean cluster deployments
      if: inputs.clean-deployment == 'true'
      continue-on-error: true
      shell: sh
      run: |
        gitrepo_exists=$(kubectl get gitrepo cluster-apps -n flux-system --ignore-not-found)

        flux suspend source git cluster-apps
        flux suspend source git flux-system

        kubectl delete --all Kustomization -A --ignore-not-found
        kubectl wait --for=delete --all Kustomization -n flux-system

    - name: Uninstall Flux
      if: inputs.clean-deployment == 'true'
      shell: sh
      run: |
        flux uninstall --silent
        kubectl wait --for=delete namespace/flux-system --timeout=60s

        kubectl delete ns vault

    - name: Install Flux
      shell: sh
      if: inputs.install-flux == 'true'
      run: |
        kubectl apply -f ${{ inputs.flux-deploy }}
        kubectl apply -f ${{ inputs.flux-config }}


name: 'Create vault secret for vaultstore'
description: 'Creates Flux controller manifests'

inputs:
  approle_secret:
    description: 'The AppRole Secret ID'
    required: true
  approle_id:
    description: 'The AppRole name'
    required: true
  replicate_to_ns:
    description: 'The namespace to replicate the secret to'
    required: true
outputs:
  secret_name:
    description: Vault values as a json file
    value: ${{ steps.vault-files.outputs.secrets_result }}

runs:
  using: 'composite'
  steps:
    - name: Configure vault access
      shell: sh
      run: |
        kubectl create ns vault \
          --dry-run=client -o yaml | \
          kubectl apply -f -

        cat <<EOF | kubectl apply -f -
        apiVersion: v1
        kind: Secret
        metadata:
          annotations:
            replicator.v1.mittwald.de/replicate-to: "${{ inputs.replicate_to_ns }}"
          name: kubeauth-secrets
          namespace: vault
        type: Opaque
        stringData:
          approle-id: ${{ inputs.approle_id }}
          secret-id: ${{ inputs.approle_secret }}
        EOF

name: 'Configure Flux Sharding'
description: 'Configures Flux sharding if enabled'

inputs:
  using_sharding:
    description: 'Whether to enable Flux sharding'
    required: true
  flux-resources-directory:
    description: 'The flux resources directory'
    required: true
  
runs:
  using: 'composite'
  steps:
    - name: Configure Flux sharding
      if: inputs.using_sharding == 'true'
      shell: sh
      run: |
        shard_dir=${{ inputs.flux-resources-directory }}/sharding

        mkdir -p $shard_dir

        mv ${{ inputs.flux-resources-directory }}/flux-deploy.yaml $shard_dir

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

    - name: Configure Flux non-sharding
      if: inputs.using_sharding == 'true'
      shell: sh
      run: |
        shard_dir=${{ inputs.flux-resources-directory }}/sharding

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

        kubectl kustomize $shard_dir -o ${{ inputs.flux-resources-directory }}/flux-deploy.yaml
