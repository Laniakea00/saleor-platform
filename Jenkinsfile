pipeline {
    agent any

    environment {
        COMPOSE_FILE = 'devops-compose.yml'
    }

    stages {
        stage('Checkout') {
            steps {
                git url: 'https://github.com/Laniakea00/saleor-platform', branch: 'main'
            }
        }

        stage('Start Monitoring Services') {
            steps {
                sh 'docker-compose -f devops-compose.yml up -d'
            }
        }

        stage('Wait for Monitoring') {
            steps {
                echo 'Waiting for monitoring tools to start...'
                sh 'sleep 20'
            }
        }

        stage('Check Running Services (Terraform + Monitoring)') {
            steps {
                script {
                    def servicesToCheck = [
                        'http://host.docker.internal:8000/health',    // Saleor API
                        'http://host.docker.internal:9000',           // Dashboard
                        'http://host.docker.internal:5432',           // Postgres
                        'http://host.docker.internal:6379',           // Redis
                        'http://host.docker.internal:9121',           // Redis-exporter
                        'http://host.docker.internal:16686',          // Jaeger

                    ]

                    for (url in servicesToCheck) {
                        echo "Checking ${url} ..."
                        sh "curl -f ${url} || echo 'WARNING: ${url} not available!'"
                    }
                }
            }
        }

        stage('Cleanup Monitoring') {
            steps {
                sh 'docker-compose -f devops-compose.yml down'
            }
        }
    }

    post {
        always {
            echo 'Shutting down monitoring stack...'
            sh 'docker-compose -f devops-compose.yml down || true'
        }
    }
}
