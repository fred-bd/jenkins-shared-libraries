package org.bede.apps;

/**
 * Runs code with secret environment variables and hides the values.
 *
 * @param varAndPasswordList - A list of strings a 'var' and 'password' key.  Example: `["TOKEN=secret"]`
 * @param Closure - The code to run in
 * @return {void}
 */
def withSecretEnv(ArrayList<String> varAndPasswordList, Closure closure) {

  def secrets = varAndPasswordList.collect { it -> 
    def v = it.split('=')
    return [var : "${v[0]}", password : "${v[1]}"]
  }

  withEnv(varAndPasswordList) {
    maskPasswords(varPasswordPairs: secrets) {
      closure()
    }
  }
}
