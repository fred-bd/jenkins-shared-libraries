package org.bede.apps;

def getTextSecret(string credentialId) {

  def result;

  withCredentials([string(credentialId: "${credentialId}", variable: 'RESULT')]) {
    result = "${RESULT}"
  }

  return result
}