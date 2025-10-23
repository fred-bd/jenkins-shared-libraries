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
  def common_name = params.CommonName
  def policies

  pipeline {
    agent { label "${agent_label}" }

    environment {
      VAULT_ADDR = "${vault_addr}"
    }

    stages {
      stage('Vault login') {
        steps {
           withCredentials(
            [[$class: 'VaultTokenCredentialBinding', 
              credentialsId: vault_cred, 
              vaultAddr: vault_addr
            ]]) {
              sh "vault login $VAULT_TOKEN"
            }
        }
      }

      stage('Configure the policies for certificates handling') {
        steps {
          script {
            policies = fileUtils.runSHScriptWithReturn([:], 'vault-scripts/configure-policies.sh')
          }
        }
      }

      stage('Configure a approle for kubernetes auth method') {
        steps {
          script {
            fileUtils.runSHScript(["policies": "${policies}"], 'vault-scripts/configure-kubeauth.sh')
          }
        }
      }

      stage('Configure certificates issuer') {
        steps {
          script {
            fileUtils.runSHScript(["common_name": "${common_name}"], 'vault-scripts/configure-certificates-issuer.sh')
          }
        }
      }
    }
  }
}