pipeline {
    agent any
    environment {
        AWS_S3_BUCKET = 'learn-jenkins-26'
    }

    stages {
        stage('Deploy to AWS') {
            agent {
                docker {
                    image 'amazon/aws-cli'
                    args '--entrypoint=""'
                    reuseNode true
                }
            }
            steps {
                withCredentials([usernamePassword(credentialsId: 'aws', passwordVariable: 'AWS_SECRET_ACCESS_KEY', usernameVariable: 'AWS_ACCESS_KEY_ID')]) {
                    sh '''
                        aws --version
                        aws ecs register-task-definition \
                            --cli-input-json aws/task-definition-prod.json

                    '''
                }
            }
        }
        stage('Build') {
            agent {
                docker {
                    image 'node:18-alpine'
                    reuseNode true
                }
            }
            steps {
                sh '''
                    ls -la
                    node --version
                    npm --version
                    npm ci
                    npm run build
                    ls -la
                '''
            }
        }
    }
}
