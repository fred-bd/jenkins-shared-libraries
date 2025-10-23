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

      stage('Test') {
        steps {
          sh 'kubectl get po -A'
        }
      }
    }
  }
}