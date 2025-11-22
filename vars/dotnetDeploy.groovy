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
              'sonar_url' : 'http://80.0.0.1:9000',
              'branch_name' : 'main',
              'path' : "${env.PATH}:/home/jenkins/dotnet:/home/jenkins/.dotnet/tools"
            ]

            def secrets = ['access_token']

            fileUtils.runSHScript(shParams, 'sonar-scripts/dotnet-scan.sh', secrets)
          }
        }
      }
    }
  }
}