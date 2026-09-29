import com.cloudbees.plugins.credentials.CredentialsScope
import com.cloudbees.plugins.credentials.domains.Domain
import com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey
import com.cloudbees.plugins.credentials.SystemCredentialsProvider
import hudson.model.Node
import hudson.slaves.DumbSlave
import hudson.slaves.RetentionStrategy
import hudson.plugins.sshslaves.SSHLauncher
import jenkins.model.Jenkins

Jenkins jenkins = Jenkins.get()
def store = SystemCredentialsProvider.getInstance().getStore()
def credentialId = 'kubeadm-ssh'
if (!store.getCredentials(Domain.global()).any { it.id == credentialId }) {
  def key = new File('/var/lib/jenkins/kubeadm.pem').text
  def credential = new BasicSSHUserPrivateKey(
    CredentialsScope.GLOBAL,
    credentialId,
    'ubuntu',
    new BasicSSHUserPrivateKey.DirectEntryPrivateKeySource(key),
    '',
    'SSH key for private build agents'
  )
  store.addCredentials(Domain.global(), credential)
}

def agents = [
  [name: 'docker-build', label: 'docker-build', host: '10.0.1.13', description: 'Docker image build agent'],
  [name: 'sonarqube', label: 'sonarqube', host: '10.0.2.187', description: 'SonarQube analysis agent']
]
for (def config : agents) {
  if (jenkins.getNode(config.name) == null) {
    def launcher = new SSHLauncher(config.host, 22, credentialId)
    def node = new DumbSlave(config.name, config.description, '/home/jenkins', '2', Node.Mode.NORMAL, config.label, launcher, new RetentionStrategy.Always(), [])
    jenkins.addNode(node)
  }
}
jenkins.save()
println 'Jenkins agents and kubeadm SSH credential configured.'
