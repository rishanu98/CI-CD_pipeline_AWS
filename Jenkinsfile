pipeline {
    agent any

    environment {
        AWS_ACCOUNT_ID = credentials('ACCOUNT_ID')
        AWS_ECR_REPO_NAME = credentials('AWS_ECR_REPO_NAME')
        REPOSITORY_URI  = "${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com"
        AWS_DEFAULT_REGION      = "us-east-1"
        SLACK_CHANNEL    = '#aws-cicd-test'

        // --- New: Git + Helm values config ---
        GIT_REPO_URL     = 'github.com/rishanu98/CI-CD_pipeline_AWS.git'
        HELM_VALUES_PATH = 'helm/values.yaml'
        GIT_USER_NAME    = 'rishanu98'
        GIT_USER_EMAIL   = 'anushab298@gmail.com'
    }

    tools {
        maven 'MAVEN3.9'
        jdk 'JDK21'
    }

    stages {

        stage('Cleaning Workspace') {
            steps {
                cleanWs()
            }
        }

        stage('Fetch code') {
            steps {
                git branch: 'main', url: 'https://github.com/rishanu98/CI-CD_pipeline_AWS.git'
            }
        }

        stage('Build'){
            steps {
                sh 'mvn clean install -DskipTests'
            }
            post {
                success {
                    echo 'Now Archiving...'
                    archiveArtifacts artifacts: '**/target/*.war'
                }
            }
        }

        stage("Unit Test") {
            steps {
                sh 'mvn test'
            }
        }

        stage("Integration Test") {
            steps {
                sh 'mvn verify -DskipUnitTests'
            }
        }

        stage("Code Analysis with checkstyle") {
            steps {
                sh 'mvn checkstyle:checkstyle'
            }
            post {
                success {
                    echo "Generated code Analysis Result"
                }
            }
        }

        stage("Code Analysis with SonarQube") {
            environment {
                scannerHome = tool 'SonarScanner'
            }
            steps {
                withSonarQubeEnv('sonarserver') {
                    sh '''
                    ${scannerHome}/bin/sonar-scanner \
                    -Dsonar.projectKey=vprofile \
                    -Dsonar.projectName=vprofile-repo \
                    -Dsonar.projectVersion=1.0 \
                    -Dsonar.sources=src/ \
                    -Dsonar.java.binaries=target/classes \
                    -Dsonar.junit.reportsPath=target/surefire-reports/ \
                    -Dsonar.java.checkstyle.reportPaths=target/checkstyle-result.xml
                    '''
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage("Build Docker Image") {
            steps {
                script {
                    dir('./Docker-files/app/') {
                            sh 'docker system prune -f'
                            sh 'docker container prune -f'
                            sh 'docker build -t ${AWS_ECR_REPO_NAME} .'
                    }
                }
            }
        }

        stage("Push Image to AWS ECR") {
            steps {
                script {
                    withCredentials([[
                        $class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: 'AWS_CREDENTIALS',  // your actual AWS credentials ID
                        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                    ]]) {
                        sh '''
                            aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin ${REPOSITORY_URI}
                            echo "Building: ${AWS_ECR_REPO_NAME}"
                            echo "Pushing to: ${REPOSITORY_URI}/${AWS_ECR_REPO_NAME}:${BUILD_NUMBER}"
                            docker tag ${AWS_ECR_REPO_NAME} ${REPOSITORY_URI}/${AWS_ECR_REPO_NAME}:${BUILD_NUMBER}
                            docker push ${REPOSITORY_URI}/${AWS_ECR_REPO_NAME}:${BUILD_NUMBER}
                        '''
                    }
                }
            }
        }

        stage("Update Helm values.yaml and Push to GitHub") {
            steps {
                script {
                    withCredentials([usernamePassword(
                        credentialsId: 'GITHUB_TOKEN',   // your actual credential ID
                        usernameVariable: 'GIT_USERNAME',
                        passwordVariable: 'GIT_TOKEN'
                    )]) {
                        sh '''
                            set -e

                            sed -i "s|^\\(\\s*image:\\s*\\).*|\\1${REPOSITORY_URI}/${AWS_ECR_REPO_NAME}|" ${HELM_VALUES_PATH}
                            sed -i "s|^\\(\\s*tag:\\s*\\).*|\\1${BUILD_NUMBER}|" ${HELM_VALUES_PATH}

                            echo "Updated values.yaml:"
                            cat ${HELM_VALUES_PATH}

                            git config user.name "${GIT_USERNAME}"
                            git config user.email "${GIT_USER_EMAIL}"

                            git add ${HELM_VALUES_PATH}

                            if git diff --cached --quiet; then
                                echo "No changes to commit."
                            else
                                git commit -m "ci: update image tag to ${BUILD_NUMBER} [skip ci]"
                                git push https://${GIT_USERNAME}:${GIT_TOKEN}@${GIT_REPO_URL} HEAD:main
                            fi
                        '''
                    }
                }
            }
        }
    }

    post {
        success {
            slackSend(
                channel: env.SLACK_CHANNEL,
                color: 'good',
                message: "Build #${env.BUILD_NUMBER} succeeded and deployed successfully. (${env.BUILD_URL})"
            )
        }

        failure {
            slackSend(
                channel: env.SLACK_CHANNEL,
                color: 'danger',
                message: "Build #${env.BUILD_NUMBER} failed. Please check Jenkins logs. (${env.BUILD_URL})"
            )
        }

        unstable {
            slackSend(
                channel: env.SLACK_CHANNEL,
                color: 'warning',
                message: "Build #${env.BUILD_NUMBER} is unstable. Check test results. (${env.BUILD_URL})"
            )
        }

        always {
            echo "Pipeline finished with status: ${currentBuild.currentResult}"
        }
    }
}