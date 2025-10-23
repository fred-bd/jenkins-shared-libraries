package org.bede.apps;

def runSHScript(Map params, String fileName, List<String> secrets = []) {
  def script = libraryResource(fileName)

  def envUtils = new EnvUtils()

  envUtils.runWithMaskedEnv(params, secrets) {
    sh script
  }
}

def runSHScriptWithReturn(Map params, String fileName, List<String> secrets = []) {
  def scr = libraryResource(fileName)
  def envUtils = new EnvUtils()
  def result

  envUtils.runWithMaskedEnv(params, secrets) {
    result = sh(returnStdout: true, script: scr).trim()
  }

  return result
}