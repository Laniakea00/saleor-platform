pipeline {
    agent any

    environment {
        COMPOSE_FILE = 'docker-compose.yml'
    }

    stages {
        stage('Checkout') {
            steps {
                git url: 'https://github.com/Laniakea00/saleor-platform', branch: 'main'
            }
        }

        stage('Build & Start Containers') {
            steps {
                sh 'docker-compose build'
                sh 'docker-compose up -d'
            }
        }

        stage('Wait for Services') {
            steps {
                sh 'sleep 30' // можно заменить на healthcheck
            }
        }

        stage('Run Tests') {
            steps {
                sh 'docker-compose exec api pytest' // запустить бэкенд-тесты
            }
        }

        stage('Stop Containers') {
            steps {
                sh 'docker-compose down'
            }
        }
    }

    post {
        always {
            sh 'docker-compose down || true'
        }
    }
}
