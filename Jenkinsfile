pipeline {
    agent any
    environment {
        IMAGE_NAME = 'ghcr.io/mdahamshi/learn-jenkins-app'
        IMAGE_TAG = "${BUILD_NUMBER}"
        GITHUB_TOKEN = credentials('github-token')
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
                    npm ci
                    npm run build
                    test -f build/index.html
                '''
            }
        }

        stage('Tests') {
            parallel {
                stage('Unit Test') {
                    agent {
                        docker {
                            image 'node:18-alpine'
                            reuseNode true
                        }
                    }
                    steps {
                        sh '''
                            npm test -- --watchAll=false \
                              --testResultsProcessor=jest-junit
                        '''
                    }
                    post {
                        always {
                            junit 'jest-results/junit.xml'
                        }
                    }
                }
                stage('E2E') {
                    agent {
                        docker {
                            image 'mcr.microsoft.com/playwright:v1.60.0-noble'
                            reuseNode true
                        }
                    }
                    steps {
                        sh '''
                            npm install serve
                            node_modules/.bin/serve -s build &
                            sleep 3
                            npx playwright test --reporter=html
                        '''
                    }
                    post {
                        always {
                            publishHTML([
                                allowMissing: false,
                                alwaysLinkToLastBuild: true,
                                keepAll: true,
                                reportDir: 'playwright-report',
                                reportFiles: 'index.html',
                                reportName: 'Playwright Report',
                                useWrapperFileDirectly: true
                            ])
                        }
                    }
                }
            }
        }

        stage('Docker Build & Push') {
            steps {
                sh '''
                    echo "$GITHUB_TOKEN" | docker login ghcr.io -u mdahamshi --password-stdin
                    docker build -t $IMAGE_NAME:$IMAGE_TAG .
                    docker tag $IMAGE_NAME:$IMAGE_TAG $IMAGE_NAME:latest
                    docker push $IMAGE_NAME:$IMAGE_TAG
                    docker push $IMAGE_NAME:latest
                    docker logout ghcr.io
                '''
            }
        }

        stage('Deploy') {
            steps {
                withCredentials([string(credentialsId: 'k3s-kubeconfig', variable: 'KUBECONFIG_CONTENT')]) {
                    sh '''
                        echo "$KUBECONFIG_CONTENT" | base64 -d > /tmp/k3s-config
                        chmod 600 /tmp/k3s-config
                        sed -i 's|newTag: ".*"|newTag: "'"$IMAGE_TAG"'"|' k8s/kustomization.yaml
                        kubectl --kubeconfig=/tmp/k3s-config apply -k k8s/
                        rm -f /tmp/k3s-config
                    '''
                }
            }
        }
    }

    post {
        always {
            sh 'docker logout ghcr.io || true'
        }
    }
}
