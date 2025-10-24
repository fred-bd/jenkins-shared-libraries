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
    # - name: Clean cluster deployments
    #   if: inputs.clean-deployment == 'true'
    #   continue-on-error: true
    #   shell: sh
    #   run: |
    #     gitrepo_exists=$(kubectl get gitrepo cluster-apps -n flux-system --ignore-not-found)

    #     flux suspend source git cluster-apps
    #     flux suspend source git flux-system

    #     kubectl delete --all Kustomization -A --ignore-not-found
    #     kubectl wait --for=delete --all Kustomization -n flux-system

    # - name: Uninstall Flux
    #   if: inputs.clean-deployment == 'true'
    #   shell: sh
    #   run: |
    #     flux uninstall --silent
    #     kubectl wait --for=delete namespace/flux-system --timeout=60s

    #     kubectl delete ns vault

    # - name: Install Flux
    #   shell: sh
    #   if: inputs.install-flux == 'true'
    #   run: |
    #     kubectl apply -f ${{ inputs.flux-deploy }}
    #     kubectl apply -f ${{ inputs.flux-config }}


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

# runs:
#   using: 'composite'
#   steps:
#     - name: Configure vault access
#       shell: sh
#       run: |
#         kubectl create ns vault \
#           --dry-run=client -o yaml | \
#           kubectl apply -f -

#         cat <<EOF | kubectl apply -f -
#         apiVersion: v1
#         kind: Secret
#         metadata:
#           annotations:
#             replicator.v1.mittwald.de/replicate-to: "${{ inputs.replicate_to_ns }}"
#           name: kubeauth-secrets
#           namespace: vault
#         type: Opaque
#         stringData:
#           approle-id: ${{ inputs.approle_id }}
#           secret-id: ${{ inputs.approle_secret }}
#         EOF

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




name: 'Create Flux Manifests'
description: 'Creates Flux controller manifests'
inputs:
  approle-secret:
    description: The approle secret
  foundation-infra-repository:
    description: The foundation-infra repository
  foundation-infra-ssh-file:
    description: The foundation-infra ssh file
  foundation-infra-ssh-pass:
    description: The foundation-infra ssh pass
  cluster-config-repository:
    description: The cluster-config repository
  cluster-config-ssh-file:
    description: The cluster-config ssh file
  cluster-config-ssh-pass:
    description: The cluster-config ssh pass
  cluster-config-path:
    description: The cluster-config path for flux profile
  helm-repo-user:
    description: The helm repo user
  helm-repo-password:
    description: The helm repo pass

outputs:
  flux-resources-directory:
    description: The flux resources directory
    value: ${{ steps.configure-output-dir.outputs.flux_resources }}

runs:
  using: 'composite'
  steps:
    - name: Configure output directory
      id: configure-output-dir
      shell: sh
      run: |
        manifests_dir=$TEMP_JOB_DIR/flux-manifests/base
        mkdir -p $manifests_dir

        echo "manifests_dir=$manifests_dir" >> $GITHUB_OUTPUT
        echo "flux_resources=$TEMP_JOB_DIR/flux-manifests" >> $GITHUB_OUTPUT

    - name: Configure foundation-infra repository
      shell: sh
      run: |
        manifests_dir=${{ steps.configure-output-dir.outputs.manifests_dir }}

        flux create secret git applications-repo-secret \
          --url=ssh://${{ inputs.foundation-infra-repository }} \
          --private-key-file=${{ inputs.foundation-infra-ssh-file }} \
          --password=${{ inputs.foundation-infra-ssh-pass }} \
          --export > $manifests_dir/foundation-infra-secret.yaml

    - name: Configure cluster config repository
      shell: sh
      run: |
        manifests_dir=${{ steps.configure-output-dir.outputs.manifests_dir }}

        flux create secret git cluster-config-secret \
          --url=ssh://${{ inputs.cluster-config-repository }} \
          --private-key-file=${{ inputs.cluster-config-ssh-file }} \
          --password=${{ inputs.cluster-config-ssh-pass }} \
          --export > $manifests_dir/cluster-config-secret.yaml

          flux create source git flux-system \
          --url=ssh://${{ inputs.cluster-config-repository }} \
          --branch=main \
          --secret-ref cluster-config-secret \
          --export > $manifests_dir/gotk-sync.yaml

          flux create kustomization flux-system \
          --source=GitRepository/flux-system \
          --path="${{ inputs.cluster-config-path }}" \
          --prune=true \
          --interval=10m \
          --export >> $manifests_dir/gotk-sync-ks.yaml

    - name: Configure helmrepostitory secret credentials
      shell: sh
      run: |
        manifests_dir=${{ steps.configure-output-dir.outputs.manifests_dir }}

        cat <<EOF > $manifests_dir/helm-repo-credentials.yaml
        apiVersion: v1
        stringData:
          username: ${{ inputs.helm-repo-user }}
          password: ${{ inputs.helm-repo-password }}
        kind: Secret
        metadata:
          name: helm-repo-credentials
          namespace: flux-system
        EOF

    - name: Generate kustomization file
      shell: sh
      run: |
        manifests_dir=${{ steps.configure-output-dir.outputs.manifests_dir }}

        files=$(ls $manifests_dir/*.yaml)

        cat <<EOF > $manifests_dir/kustomization.yaml
        apiVersion: kustomize.config.k8s.io/v1beta1
        resources:
        EOF

        for file in $files; do
          echo "  - $(basename $file)" >> $manifests_dir/kustomization.yaml
        done

    - name: Generate flux-config
      shell: sh
      run: |
        manifests_dir=${{ steps.configure-output-dir.outputs.manifests_dir }}
        kubectl kustomize $manifests_dir -o $manifests_dir/../flux-config.yaml

    - name: Generate flux-deploy
      shell: sh
      run: |
        manifests_dir=${{ steps.configure-output-dir.outputs.manifests_dir }}

        flux install \
          --export > $manifests_dir/../flux-deploy.yaml

