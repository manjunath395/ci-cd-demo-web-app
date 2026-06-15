pipeline {

    agent any

    environment {

        APP_NAME = "demo-webapp"

        DOCKERHUB_REPO = "manjunath9795/demo-webapp"

        IMAGE_TAG = "${BUILD_NUMBER}"

        SONARQUBE_ENV = "SonarQube"

        KUBECONFIG_FILE = credentials('kubeconfig')
    }

    options {
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: '20'))
    }

    stages {

        stage('Checkout') {

            steps {

                git branch: 'main',
                    credentialsId: 'github-creds',
                    url: 'https://github.com/manjunath395/ci-cd-demo-web-app.git'
            }
        }

        stage('Install Dependencies') {

            steps {
                sh 'npm install'
            }
        }

        stage('Unit Tests') {

            steps {
                sh 'npm test'
            }
        }

        stage('SonarQube Scan') {

            steps {

                withSonarQubeEnv("${SONARQUBE_ENV}") {

                    sh '''
                    sonar-scanner \
                    -Dsonar.projectKey=demo-webapp \
                    -Dsonar.sources=. \
                    -Dsonar.host.url=$SONAR_HOST_URL \
                    -Dsonar.login=$SONAR_AUTH_TOKEN
                    '''
                }
            }
        }

        stage('Build Docker Image') {

            steps {

                sh """
                docker build \
                -t ${DOCKERHUB_REPO}:${IMAGE_TAG} .
                """
            }
        }

        stage('Trivy Scan') {

            steps {

                sh """
                trivy image \
                --exit-code 1 \
                --severity HIGH,CRITICAL \
                ${DOCKERHUB_REPO}:${IMAGE_TAG}
                """
            }
        }

        stage('Push To DockerHub') {

            steps {

                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-creds',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )
                ]) {

                    sh '''
                    echo $DOCKER_PASS | docker login \
                    -u $DOCKER_USER \
                    --password-stdin

                    docker push ${DOCKERHUB_REPO}:${IMAGE_TAG}

                    docker tag ${DOCKERHUB_REPO}:${IMAGE_TAG} \
                               ${DOCKERHUB_REPO}:latest

                    docker push ${DOCKERHUB_REPO}:latest
                    '''
                }
            }
        }

        stage('Update Kubernetes Manifest') {

            steps {

                sh """
                sed -i \
                's|image:.*|image: ${DOCKERHUB_REPO}:${IMAGE_TAG}|g' \
                deployment.yaml
                """
            }
        }

        stage('Deploy To EKS') {

            steps {

                withEnv(["KUBECONFIG=${KUBECONFIG_FILE}"]) {

                    sh '''
                    kubectl apply -f deployment.yaml
                    kubectl apply -f service.yaml
                    kubectl apply -f ingress.yaml
                    '''
                }
            }
        }

        stage('Verify Rollout') {

            steps {

                withEnv(["KUBECONFIG=${KUBECONFIG_FILE}"]) {

                    sh '''
                    kubectl rollout status \
                    deployment/demo-webapp \
                    --timeout=300s
                    '''
                }
            }
        }

        stage('Production Approval') {

            when {
                branch 'main'
            }

            steps {

                input message: 'Deploy to Production?'
            }
        }
    }

    post {

        success {

            echo "Deployment Successful"

            mail to: 'manjunathmi8147@gmail.com',
                 subject: "SUCCESS: Build ${BUILD_NUMBER}",
                 body: "Deployment completed successfully."
        }

        failure {

            echo "Deployment Failed"

            mail to: 'manjunathmi8147@gmail.com',
                 subject: "FAILED: Build ${BUILD_NUMBER}",
                 body: "Deployment failed. Please investigate."
        }

        always {

            cleanWs()
        }
    }
}
