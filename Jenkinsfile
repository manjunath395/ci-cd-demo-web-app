pipeline {

    agent {
        label 'docker'
    }

    environment {

        APP_NAME = "demo-webapp"

        ECR_REPO = "867492128202.dkr.ecr.ap-south-1.amazonaws.com/demo-webapp"

        IMAGE_TAG = "${BUILD_NUMBER}"

        // SONARQUBE_ENV = "SonarQube"

        KUBECONFIG_FILE = credentials('kubeconfig')
    }

    options {
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: '20'))
    }

    stages {

        // stage('Checkout') {

        //     steps {

        //         git branch: 'main',
        //             credentialsId: 'github-creds',
        //             url: 'https://github.com/manjunath395/ci-cd-demo-web-app.git'
        //     }
        // }

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

        // stage('SonarQube Scan') {

        //     steps {

        //         withSonarQubeEnv("${SONARQUBE_ENV}") {

        //             sh '''
        //             sonar-scanner \
        //             -Dsonar.projectKey=demo-webapp \
        //             -Dsonar.sources=. \
        //             -Dsonar.host.url=$SONAR_HOST_URL \
        //             -Dsonar.login=$SONAR_AUTH_TOKEN
        //             '''
        //         }
        //     }
        // }

        stage('Build Docker Image') {

            steps {

                sh """
                docker build \
                -t ${ECR_REPO}:${IMAGE_TAG} .
                """
            }
        }

        // stage('Trivy Scan') {

        //     steps {

        //         sh """
        //         trivy image \
        //         --exit-code 1 \
        //         --severity HIGH,CRITICAL \
        //         ${ECR_REPO}:${IMAGE_TAG}
        //         """
        //     }
        // }

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

                    docker push ${ECR_REPO}:${IMAGE_TAG}

                    docker tag ${ECR_REPO}:${IMAGE_TAG} \
                               ${ECR}:latest

                    docker push ${ECR_REPO}:latest
                    '''
                }
            }
        }

        stage('Update Kubernetes Manifest') {

            steps {

                sh """
                sed -i \
                's|image:.*|image: ${ECR_REPO}:${IMAGE_TAG}|g' \
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

        // stage('Verify Rollout') {

        //     steps {

        //         withEnv(["KUBECONFIG=${KUBECONFIG_FILE}"]) {

        //             sh '''
        //             kubectl rollout status \
        //             deployment/demo-webapp \
        //             --timeout=300s
        //             '''
        //         }
        //     }
        // }

        // stage('Production Approval') {

        //     when {
        //         branch 'main'
        //     }

        //     steps {

        //         input message: 'Deploy to Production?'
        //     }
        // }
    }

    post {

        success {

            echo "Deployment Successfull"

            // mail to: 'manjunathmi8147@gmail.com',
            //      subject: "SUCCESS: Build ${BUILD_NUMBER}",
            //      body: "Deployment completed successfully."
        }

        failure {

            echo "Deployment Failed"

            // mail to: 'manjunathmi8147@gmail.com',
            //      subject: "FAILED: Build ${BUILD_NUMBER}",
            //      body: "Deployment failed. Please investigate."
        }

        always {

            cleanWs()
        }
    }
}
