pipeline {
    agent any
    environment {
        AWS_S3_BUCKET = 'learn-jenkins-26'
        AWS_DEFAULT_REGION = 'us-east-1'
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
                            --cli-input-json file://aws/task-definition-prod.json
                        aws ecs update-service \
                            --cluster worthy-butterfly-hlfyov \
                            --service learnJenkinsApp-TaskDefenition-Prod-service-7rk2bivu  \
                            --task-definition learnJenkinsApp-TaskDefenition-Prod:2

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
