package org.bede.apps;

def getSecretsList(List<String> envList, List<String> secrets) {
  def secList = secrets.collect { i -> envList.findIndexOf{it ==~ /${i.toUpperCase()}.*/ } }
  return secList.collect { i -> envList[i] }
}

def runWithMaskedEnv(Map params, List<String> secrets, Closure closure) {
  def envList = params.collect { it -> "${it.key.toUpperCase()}=${it.value}" }

  if(secrets) {
    def secList = getSecretsList(envList, secrets)

    new SecretUtils().withSecretEnv(secList) {
      withEnv(envList) { 
        closure() 
      }
    }
  } else {
    withEnv(envList) { 
      closure() 
    }
  }
}