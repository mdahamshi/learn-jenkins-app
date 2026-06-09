pipeline {
    agent any
    environment {
        AWS_DOCKER_REGISTRY = '953907014716.dkr.ecr.us-east-1.amazonaws.com'
        REACT_APP_VERSION = "1.0.$BUILD_ID"
        APP_NAME = 'learnjenkinsapp'
        AWS_S3_BUCKET = 'learn-jenkins-26'
        AWS_DEFAULT_REGION = 'us-east-1'
        AWS_ECS_CLUSTER = 'worthy-butterfly-hlfyov '
        AWS_ECS_SERVICE_PROD = 'learnJenkinsApp-TaskDefenition-Prod-service-7rk2bivu'
        AWS_ECS_TD_PROD = 'learnJenkinsApp-TaskDefenition-Prod'
    }

    stages {
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

        stage('Build Docker image') {
            agent {
                docker {
                    image 'myaws'
                    args '-v /var/run/docker.sock:/var/run/docker.sock -u root --entrypoint=""'
                    reuseNode true
                }
            }
            steps {
                withCredentials([usernamePassword(credentialsId: 'aws', passwordVariable: 'AWS_SECRET_ACCESS_KEY', usernameVariable: 'AWS_ACCESS_KEY_ID')]) {
                    sh '''
                    docker build -t $AWS_DOCKER_REGISTRY/$APP_NAME:$REACT_APP_VERSION .
                    aws ecr get-login-password | \
                        docker login --username AWS --password-stdin $AWS_DOCKER_REGISTRY
                    docker push $AWS_DOCKER_REGISTRY/$APP_NAME:$REACT_APP_VERSION

                '''
                }
            }
        }

        stage('Deploy to AWS') {
            agent {
                docker {
                    image 'myaws'
                    args '--entrypoint=""'
                    reuseNode true
                }
            }
            steps {
                withCredentials([usernamePassword(credentialsId: 'aws', passwordVariable: 'AWS_SECRET_ACCESS_KEY', usernameVariable: 'AWS_ACCESS_KEY_ID')]) {
                    sh '''
                        aws --version
                        sed 
                        LATEST_TD_REVISION=$(aws ecs register-task-definition \
                            --cli-input-json file://aws/task-definition-prod.json | jq '.taskDefinition.revision')
                        aws ecs update-service \
                            --cluster $AWS_ECS_CLUSTER \
                            --service $AWS_ECS_SERVICE_PROD  \
                            --task-definition $AWS_ECS_TD_PROD:$LATEST_TD_REVISION
                        aws ecs wait services-stable \
                            --cluster $AWS_ECS_CLUSTER  \
                            --services $AWS_ECS_SERVICE_PROD

                    '''
                }
            }
        }
    }
}
