import org.jenkinsci.plugins.workflow.cps.DSL

def call(body) {
  def fileUtils = new org.bede.apps.FileUtils()

  def config = [:]
  body.resolveStrategy = Closure.DELEGATE_FIRST
  body.delegate = config
  body()

  def vault_cred = config.credentialId
  def agent_label = config.agentName
  def vault_addr = params.VaultAddr
  def kubefilePath = params.KubeFilePath
  def kubefileSecret = params.KubeFileSecret
  def ns_replication = params.KubeAuthNs
  def cleanAll = params.CleanFluxResources

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
            script { fileUtils.runSHScript(["ns_to_replicate":"${ns_replications}"], 'flux-scripts/configure-kubeauth-secret.sh') }
          }
        }
      }
    }
  }
}