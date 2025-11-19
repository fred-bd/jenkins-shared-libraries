package org.bede.apps;

def getTextSecret(String credentialId) {

  def result;

  withCredentials([string(credentialsId: "${credentialId}", variable: 'RESULT')]) {
    result = "${RESULT}"
  }

  return result
}