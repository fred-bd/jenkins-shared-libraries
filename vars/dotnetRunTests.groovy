import org.jenkinsci.plugins.workflow.cps.DSL

def call(body) {
  // def fileUtils = new org.bede.apps.FileUtils()0

  def config = [:]
  body.resolveStrategy = Closure.DELEGATE_FIRST
  body.delegate = config
  body()

  // def vault_cred = config.credentialId
  // def agent_label = config.agentName
  // def helmSecretPath = config.helmSecretPath
  // def helmUserKey = config.helmUserKey
  // def helmPasswordKey = config.helmPasswordKey

  // def vault_addr = params.VaultAddr
  // def kubefilePath = params.KubeFilePath
  // def kubefileSecret = params.KubeFileSecret
  // def ns_replication = params.KubeAuthNs
  // def cleanAll = params.CleanFluxResources
  // def shardEnabled = params.ConfigureSharding
  // def clustersRepo = params.FluxConfigRepo 
  // def clustersRepoPath = params.FluxConfigRepoPath

  // def fluxManifestsDir

  pipeline {
    // agent { label "${agent_label}" }

    // environment {
    //   VAULT_ADDR = "${vault_addr}"
    // }

    stages {
      stage('test') {
        steps {
          sh 'echo ok'
        }
      }
    }
  }
}