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
    v = it.split('=')
    return [var : "${v[0]}", password : "${v[1]}"]
  }

  withEnv(varAndPasswordList) {
    maskPasswords(varPasswordPairs: secrets) {
      closure()
    }
  }
}



//  def secrets = [
//         [path: 'secret/testing', engineVersion: 1, secretValues: [
//             [envVar: 'testing', vaultKey: 'value_one'],
//             [envVar: 'testing_again', vaultKey: 'value_two']]],
//         [path: 'secret/another_test', engineVersion: 2, secretValues: [
//             [vaultKey: 'another_test']]]
//     ]

//     // optional configuration, if you do not provide this the next higher configuration
//     // (e.g. folder or global) will be used
//     def configuration = [vaultUrl: 'http://my-very-other-vault-url.com',
//                          vaultCredentialId: 'my-vault-cred-id',
//                          engineVersion: 1]
//     // inside this block your credentials will be available as env variables
//     withVault([configuration: configuration, vaultSecrets: secrets]) {
//         sh 'echo $testing'
//         sh 'echo $testing_again'
//         sh 'echo $another_test'
//     }