import org.jenkinsci.plugins.workflow.cps.DSL

def call(body) {

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
      stage('test') {
        steps {
          sh """
            echo $PWD
            ls -la
          """
        }
      }
    }
  }
}