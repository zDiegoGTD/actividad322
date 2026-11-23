hudson.plugins.sonar.SonarInstallation.class.getConstructors().each { println it }
println '---RUNNER---'
hudson.plugins.sonar.SonarRunnerInstallation.class.getConstructors().each { println it }
