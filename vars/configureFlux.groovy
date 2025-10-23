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
  def policies

  pipeline {
    agent { label "${agent_label}" }

    environment {
      VAULT_ADDR = "${vault_addr}"
    }

    stages {
      stage('Test') {
        steps {
          def secrets = [
            [path: "${kubefilePath}", engineVersion: 2, secretValues: [
              [envVar: 'kubeconfig', vaultKey: "${kubefileSecret}" ]]]
          ]

          def configuration = [vaultUrl: "${vault_addr}",
                              vaultCredentialId: "${vault_cred}",
                              engineVersion: 2]
          // inside this block your credentials will be available as env variables
          withVault([configuration: configuration, vaultSecrets: secrets]) {
              sh 'cat $kubeconfig'
          }
        }
      }
    }
  }
}