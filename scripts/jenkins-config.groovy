// Configuracion de Jenkins para la actividad 3.2.2:
//   - credencial con el token de analisis de SonarQube
//   - servidor SonarQube-DSO
//   - herramienta SonarScanner-DSO
//   - job de tipo Pipeline leido desde el repositorio (Pipeline script from SCM)
import jenkins.model.Jenkins
import hudson.util.Secret
import com.cloudbees.plugins.credentials.CredentialsScope
import com.cloudbees.plugins.credentials.SystemCredentialsProvider
import com.cloudbees.plugins.credentials.domains.Domain
import org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl
import hudson.plugins.sonar.SonarGlobalConfiguration
import hudson.plugins.sonar.SonarInstallation
import hudson.plugins.sonar.SonarRunnerInstallation
import hudson.plugins.sonar.model.TriggersConfig
import hudson.plugins.git.GitSCM
import hudson.plugins.git.BranchSpec
import org.jenkinsci.plugins.workflow.job.WorkflowJob
import org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition

def j = Jenkins.get()
def token = new File('/var/jenkins_home/sonar_token.txt').text.trim()

// ---- 1. Credencial con el token -------------------------------------------
def store = SystemCredentialsProvider.getInstance().getStore()
store.getCredentials(Domain.global()).findAll { it.id == 'sonarqube-token' }.each {
    store.removeCredentials(Domain.global(), it)
}
store.addCredentials(Domain.global(), new StringCredentialsImpl(
        CredentialsScope.GLOBAL, 'sonarqube-token',
        'Token de analisis de SonarQube', Secret.fromString(token)))
println 'credencial sonarqube-token: OK'

// ---- 2. Servidor SonarQube -------------------------------------------------
def cfg = j.getDescriptorByType(SonarGlobalConfiguration.class)
// Firma: (nombre, url, credentialsId, webhookSecretId, mojoVersion, triggers, propiedades)
def inst = new SonarInstallation(
        'SonarQube-DSO', 'http://sonarqube:9000', 'sonarqube-token',
        null, null, new TriggersConfig(), null)
cfg.setInstallations(inst)
cfg.save()
println 'servidor SonarQube-DSO: OK'

// ---- 3. Herramienta SonarScanner ------------------------------------------
def sd = j.getDescriptorByType(SonarRunnerInstallation.DescriptorImpl.class)
sd.setInstallations(new SonarRunnerInstallation('SonarScanner-DSO', '/opt/sonar-scanner', []))
sd.save()
println 'herramienta SonarScanner-DSO: OK'

// ---- 4. Job de tipo Pipeline desde SCM ------------------------------------
def nombre = 'actividad322-pipeline'
def existente = j.getItem(nombre)
if (existente != null) { existente.delete() }

def job = j.createProject(WorkflowJob, nombre)
job.setDescription('Pipeline DevSecOps de la actividad 3.2.2 (Build, Test, Analyze, Security Test y Deploy)')
def scm = new GitSCM('https://github.com/zDiegoGTD/actividad322.git')
scm.branches = [new BranchSpec('*/actividad322')]
job.setDefinition(new CpsScmFlowDefinition(scm, 'Jenkinsfile'))
job.save()
println 'job actividad322-pipeline: OK'

j.save()
println 'CONFIGURACION COMPLETADA'
