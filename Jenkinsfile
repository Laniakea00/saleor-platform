pipeline {
    agent any
    environment {
        COMPOSE_FILE = 'devops-compose.yml'
        PATH = "/root/.local/bin:$PATH"
    }

    stages {
        stage('Checkout') {
            steps {
                git url: 'https://github.com/Laniakea00/saleor-platform', branch: 'main'
            }
        }

        stage('Setup Tools') {
            steps {
                sh '''
                    apt-get update
                    apt-get install -y netcat-openbsd python3 python3-pip
                '''
            }
        }

        stage('Install Poetry') {
            steps {
                sh '''
                    python3 -m venv venv
                    . venv/bin/activate
                    pip install poetry
                '''
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

        stage('Run Tests') {
            steps {
                dir('saleor') {
                    echo 'Installing dependencies and running tests...'
                    sh 'pip install poetry'
                    sh 'poetry install'
                    sh 'poetry run pytest'
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
