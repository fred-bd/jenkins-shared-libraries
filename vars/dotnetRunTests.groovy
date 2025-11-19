import org.jenkinsci.plugins.workflow.cps.DSL

def call(body) {

  def credUtils = new org.bede.apps.CredentialUtils()
  def secretUtils = new org.bede.apps.SecretUtils()
  def fileUtils = new org.bede.apps.FileUtils()

  def config = [:]
  body.resolveStrategy = Closure.DELEGATE_FIRST
  body.delegate = config
  body()

  def sonar_cred = config.credentialId
  def agent_label = config.agentName
  def project_id = config.sonarProjectId

  pipeline {
    agent { label "${agent_label}" }

    stages {
      stage('Build and scan') {
        steps {
          script {
            def sonarToken = credUtils.getTextSecret(sonar_cred)
            def shParams = [
              'project_id' : project_id,
              'access_token' : sonarToken,
              'sonar_url' : 'http://sonarqube:9000',
              'branch_name' : env.BRANCH_NAME
            ]

            def secrets = ['access_token']

            fileUtils.runSHScript(shParams, 'sonar-scripts/dotnet-scan.sh', secrets)

            // def secrets = [
            //   [path: "${helmSecretPath}", engineVersion: 2, secretValues: [
            //     [envVar: 'user', vaultKey: "${helmUserKey}"],
            //     [envVar: 'pass', vaultKey: "${helmPasswordKey}"]]]
            // ]

            // def configuration = [vaultUrl: vault_addr, vaultCredentialId: vault_cred, engineVersion: 1]

            // withVault([configuration: configuration, vaultSecrets: secrets]) {
            //   def shParams = [
            //     'helm_artifact_user' : user,
            //     'helm_artifact_password' : pass,
            //     'cluster_config_repository' : clustersRepo,
            //     'cluster_config_path' : clustersRepoPath 
            //   ]

            //   fluxManifestsDir = fileUtils.runSHScriptWithReturn(shParams, 'flux-scripts/generate-flux-manifests.sh') 
            }
          }
        }
      }
    }
  }
}