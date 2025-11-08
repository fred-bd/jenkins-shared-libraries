import org.jenkinsci.plugins.workflow.cps.DSL

def call(body) {
  def config = [:]
  body.resolveStrategy = Closure.DELEGATE_FIRST
  body.delegate = config
  body()

  pipeline {
    agent any

    stages {
      stage('test') {
        steps {
          sh """
            echo ok
          """
        }
      }
    }
  }
}