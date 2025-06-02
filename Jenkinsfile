pipeline {
    agent any

    environment {
    COMPOSE_FILE = 'devops-compose.yml'
    SALEOR_DIR = 'saleor'
    }

    stages {
        stage('Checkout') {
            steps {
                git url: 'https://github.com/Laniakea00/saleor-platform', branch: 'main'
            }
        }

        stage('Install System Tools') {
            steps {
                sh '''
                    apt-get update
                    apt-get install -y python3 python3-pip python3-venv curl netcat-openbsd
                '''
            }
        }

        stage('Start Monitoring Services') {
            steps {
                sh 'docker-compose -f ${COMPOSE_FILE} up -d'
            }
        }

        stage('Wait for Monitoring') {
            steps {
                echo 'Waiting for monitoring tools to start...'
                sh 'sleep 20'
            }
        }

        stage('Check Running Services') {
            steps {
                script {
                    def httpServices = [
                        'http://host.docker.internal:8000/health',
                        'http://host.docker.internal:9000',
                        'http://host.docker.internal:9121',
                        'http://host.docker.internal:16686'
                    ]
                    def tcpServices = [
                        [host: 'host.docker.internal', port: 5432],
                        [host: 'host.docker.internal', port: 6379]
                    ]

                    httpServices.each { url ->
                        echo "Checking ${url} ..."
                        try {
                            sh "curl -f ${url}"
                        } catch (e) {
                            echo "WARNING: ${url} not available!"
                        }
                    }

                    tcpServices.each { s ->
                        echo "Checking TCP ${s.host}:${s.port} ..."
                        try {
                            sh "nc -zv ${s.host} ${s.port}"
                        } catch (e) {
                            echo "WARNING: TCP ${s.host}:${s.port} not available!"
                        }
                    }
                }
            }
        }

        stage('Cleanup Monitoring') {
            steps {
                sh 'docker-compose -f ${COMPOSE_FILE} down'
            }
        }
    }

    post {
        always {
            echo 'Shutting down monitoring stack...'
            sh 'docker-compose -f ${COMPOSE_FILE} down || true'
        }
    }
}
