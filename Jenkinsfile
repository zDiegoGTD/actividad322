pipeline {
    agent any

    environment {
        APP_NAME = 'appsegura'
        REPORTS  = 'reportes-seguridad'
    }

    stages {
        stage('Build') {
            steps {
                sh 'python3 -m py_compile hola.py app.py app_seguro.py'
                echo 'Compilacion sintactica correcta'
            }
        }

        stage('Test') {
            steps {
                sh 'python3 -m unittest discover -v'
            }
        }

        stage('Analyze (SAST - SonarQube)') {
            steps {
                script {
                    def scanner = tool 'SonarScanner-DSO'
                    withSonarQubeEnv('SonarQube-DSO') {
                        // El token se toma de la credencial sonarqube-token que
                        // inyecta withSonarQubeEnv; nunca se escribe en el Jenkinsfile.
                        sh """
                            ${scanner}/bin/sonar-scanner \
                                -Dsonar.host.url="\$SONAR_HOST_URL" \
                                -Dsonar.token="\${SONAR_AUTH_TOKEN:-\$SONAR_TOKEN}"
                        """
                    }
                }
            }
        }

        stage('Security Test (SCA + DAST)') {
            steps {
                sh 'mkdir -p ${REPORTS}'

                // SCA: analisis de dependencias con OSV-Scanner
                sh '''docker run --rm -v $(pwd):/src:ro \
                        ghcr.io/google/osv-scanner:v2 scan source -r /src \
                        --format json > ${REPORTS}/osv.report.json || true'''

                // DAST: OWASP ZAP en modo linea base
                sh '''docker run --rm -t --network red-dso \
                        -v $(pwd)/${REPORTS}:/zap/wrk:rw \
                        ghcr.io/zaproxy/zaproxy:stable zap-baseline.py \
                        -t http://appsegura:5000/hello?name=TEST \
                        -r zap-report.html || true'''
            }
        }

        stage('Deploy') {
            steps {
                sh 'docker build -t ${APP_NAME} .'
                sh 'docker rm -f ${APP_NAME} || true'
                sh 'docker run -d --name ${APP_NAME} --network red-dso -p 5000:5000 ${APP_NAME}'
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'reportes-seguridad/**', allowEmptyArchive: true
        }
    }
}
