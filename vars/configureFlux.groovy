import org.jenkinsci.plugins.workflow.cps.DSL

def call(body) {
  def fileUtils = new org.bede.apps.FileUtils()

  def config = [:]
  body.resolveStrategy = Closure.DELEGATE_FIRST
  body.delegate = config
  body()

  def vault_cred = config.credentialId
  def agent_label = config.agentName
  def helmSecretPath = config.helmSecretPath
  def helmUserKey = config.helmUserKey
  def helmPasswordKey = config.helmPasswordKey

  def vault_addr = params.VaultAddr
  def kubefilePath = params.KubeFilePath
  def kubefileSecret = params.KubeFileSecret
  def ns_replication = params.KubeAuthNs
  def cleanAll = params.CleanFluxResources
  def shardEnabled = params.ConfigureSharding
  def clustersRepo = params.FluxConfigRepo 
  def clustersRepoPath = params.FluxConfigRepoPath

  def fluxManifestsDir

  pipeline {
    agent { label "${agent_label}" }

    environment {
      VAULT_ADDR = "${vault_addr}"
    }

    stages {
      stage('Configure kubeconfig file') {

        steps {
          withCredentials(
          [[$class: 'VaultTokenCredentialBinding', 
            credentialsId: vault_cred, 
            vaultAddr: vault_addr
          ]]) {
            script {
              env.KUBECONFIG = fileUtils.runSHScriptWithReturn(
                ["secret_key":"${kubefileSecret}", "kv_engine_path":"${kubefilePath}"], 
                'flux-scripts/configure-kubeconfig.sh'
              )
            }
          }
        }
      }

      stage('Clean cluster') {
        when {
          expression { cleanAll == true }
        }

        steps {
          script { fileUtils.runSHScript([:], 'flux-scripts/clean-cluster.sh') }
        }
      }

      stage('Configure kubeauth authentication secret') {

        steps {
          withCredentials(
          [[$class: 'VaultTokenCredentialBinding', 
            credentialsId: vault_cred, 
            vaultAddr: vault_addr
          ]]) {
            script { fileUtils.runSHScript(["ns_to_replicate":"${ns_replication}"], 'flux-scripts/configure-kubeauth-secret.sh') }
          }
        }
      }

      stage('Configure flux manifests') {

        steps {
          script {
            def secrets = [
              [path: "${helmSecretPath}", engineVersion: 2, secretValues: [
                [envVar: 'user', vaultKey: "${helmUserKey}"],
                [envVar: 'pass', vaultKey: "${helmPasswordKey}"]]]
            ]

            def configuration = [vaultUrl: vault_addr, vaultCredentialId: vault_cred, engineVersion: 1]

            withVault([configuration: configuration, vaultSecrets: secrets]) {
              def shParams = [
                'helm_artifact_user' : user,
                'helm_artifact_password' : pass,
                'cluster_config_repository' : clustersRepo,
                'cluster_config_path' : clustersRepoPath 
              ]

              fluxManifestsDir = fileUtils.runSHScriptWithReturn(shParams, 'flux-scripts/generate-flux-manifests.sh') 
            }
          }
        }
      }

      stage('Configure Flux sharding') {

        when {
          expression { shardEnabled == true }
        }

        steps {
          script {
            def shParams = [ 'flux_manifests_dir' : fluxManifestsDir ]
            fileUtils.runSHScript(shParams, 'flux-scripts/configure-flux-sharding.sh') 
          }
        }
      }

      stage('Deploy Flux') {
        steps {
          script {
            sh "kubectl apply -k ${fluxManifestsDir}"
          }
        }
      }
    }
  }
}