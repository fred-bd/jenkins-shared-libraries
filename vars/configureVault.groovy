import org.jenkinsci.plugins.workflow.cps.DSL

def call(body) {
  // def gitUtils = new org.bede.apps.GitUtils()
  def fileUtils = new org.bede.apps.FileUtils()
  // def credUtils = new org.bede.apps.CredentialsUtils()

  def config = [:]
  body.resolveStrategy = Closure.DELEGATE_FIRST
  body.delegate = config
  body()

  def vault_cred = config.credentialId
  // def folder = config.folder
  // def branch = config.branch ?: 'main'
  // def credentialId = config.credentialId
  // def dindImageName = config.dindImageName ?: 'docker:26.0.1-dind'

  // def imageName = params.Name
  // def imageTag = params.Tag
  def vault_addr = params.VaultAddr
  def policies
  def kubeauth_approle
  // def registryCredentials = params.RegistryCredentials
  // def pushToRegistry = params.Push
  // def scanImage = params.Scan


  // def dindPort
  // def containerName
  // def certsPath = '/home/jenkins/agent/.cert'
  // def dindConfigsList = [ 'dind_image_name' : dindImageName ]
  // def dockerHostDind
  // def scanFailed = false

  pipeline {
    agent { label 'kube-agent' }

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
    }
      
    //   stage('Get dind server name') {
    //     steps {
    //       script {
    //         containerName = filesUtils.runSHScriptWithReturn(['container_name' : 'dind-server'], 'docker-scripts/get-dind-server-name.sh')
    //       } 
    //     }
    //   }

    //   stage('Get dind port') {
    //     steps {
    //       script {
    //         dindPort = filesUtils.runSHScriptWithReturn(['port' : 2684 ], 'docker-scripts/find-dind-port.sh')
    //       } 
    //     }
    //   }

    //   stage('Init dind server') {
    //     steps {
    //       script {
    //         def shParams = [
    //           'image_name' : dindImageName,
    //           'container_name' : containerName,
    //           'dind_port' : dindPort
    //         ]

    //         filesUtils.runSHScript(shParams, 'docker-scripts/init-docker-server.sh')

    //         def dindIp = sh(
    //           returnStdout: true, 
    //           script: "docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ${containerName}").trim()

    //         dockerHostDind = "tcp://${dindIp}:${dindPort}"

    //         dindConfigsList.putAll([
    //           'dind_host' : dockerHostDind
    //         ])
    //       }
    //     }
    //   }

    //   stage('Get Dockerfiles repository') {
    //     steps {
    //       script { 
    //         gitUtils.downloadRepository(url, folder, branch, credentialId)
    //       }
    //     }
    //   }

    //   stage('Build docker image') {
    //     steps {
    //       script {
    //         def shParams = [
    //           'image_name' : imageName,
    //           'folder' : folder,
    //           'docker_tls_verify' : '',
    //           'docker_tls' : '',
    //           'docker_host' : dockerHostDind
    //         ]

    //         shParams << dindConfigsList

    //         filesUtils.runSHScript(shParams, 'docker-scripts/build-image.sh')
    //       }
    //     }
    //   }

    //   stage('Scan new image') {
    //     when {
    //       expression { scanImage }
    //     }
    //     steps {
    //       script {
    //         try {
    //           def (user, pass) = credUtils.getUserPasswordCredentials(registryCredentials)
    //           def shParams = [
    //             'docker_user' : user,
    //             'docker_pass' : pass,
    //             'image_name' : imageName
    //           ]

    //           shParams << dindConfigsList

    //           filesUtils.runSHScript(shParams, 'docker-scripts/scan-image.sh', ['docker_pass'])
    //         } catch (Exception e) {
    //           scanFailed = true
    //         }
    //       }
    //     }
    //   }

    //   stage('Checking scout recommendations') {
    //     when {
    //       expression { scanFailed }
    //     }
    //     steps {
    //       script {
    //           def (user, pass) = credUtils.getUserPasswordCredentials(registryCredentials)
    //           def shParams = [
    //             'docker_user' : user,
    //             'docker_pass' : pass,
    //             'image_name' : imageName
    //             // 'dind_container_name' : containerName
    //           ]

    //           shParams << dindConfigsList

    //           filesUtils.runSHScript(shParams, 'docker-scripts/scout-recommendations.sh', ['docker_pass'])
    //       }
    //     }
    //   }

    //   stage('Push Approval') {
    //     when {
    //       expression { scanFailed && pushToRegistry }
    //     }
    //     steps {
    //       input 'Do you want to continue and push the image?'
    //     }
    //   }

    //   stage('Push new image') {
    //     when {
    //       expression { pushToRegistry }
    //     }
    //     steps {
    //       script {
    //         def (user, pass) = credUtils.getUserPasswordCredentials(registryCredentials)
    //         def shParams = [
    //           'docker_user' : user,
    //           'docker_pass' : pass,
    //           'image_name' : imageName,
    //           'image_tag' : imageTag,
    //           'docker_tls_verify' : '',
    //           'docker_tls' : '',
    //           'docker_host' : dockerHostDind
    //          ]

    //         // shParams << dindConfigsList

    //         filesUtils.runSHScript(shParams, 'docker-scripts/docker-push.sh', ['docker_pass'])
    //       }
    //     }
    //   }

    // }
    // post { 
    //   always { 
    //     script {
    //       sh "docker stop ${containerName} && docker volume prune -f"
    //     } 
    //   } 
    // }
  }
}