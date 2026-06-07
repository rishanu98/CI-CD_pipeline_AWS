pipeline {
    agent any

    environment {
        registryUrl = "https://<aws-account-id>.dkr.ecr.us-east-1.amazonaws.com"
        imageName   = "<aws-account-id>.dkr.ecr.us-east-1.amazonaws.com/vprofile-app"
        awsCred     = "awscred"
        cluster     = "vprofile-cluster"
        service     = "vprofile-service"
        region      = "us-east-1"
    }

    tools {
        maven 'Maven'
        jdk 'JDK'
    }

    stages {

        stage('BUILD'){
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

        stage("Test") {
            steps {
                sh 'mvn test'
            }
        }

        stage("Code Analysis with SonarQube") {
            environment {
                scannerHome = tool 'sonarserver'
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

        stage("Build Docker Image") {
            steps {
                script {
                    dockerImage = docker.build(
                        "${imageName}:${BUILD_NUMBER}",
                        "./Docker-files/app/multistage/"
                    )
                }
            }
        }

        stage("Push Image to AWS ECR") {
            steps {
                script {
                    docker.withRegistry(registryUrl, "ecr:${region}:${awsCred}") {
                        dockerImage.push("${BUILD_NUMBER}")
                        dockerImage.push("latest")
                    }
                }
            }
        }

        stage("Deploy to AWS ECS") {
            steps {
                withAWS(credentials: "${awsCred}", region: "${region}") {
                    sh '''
                    aws ecs update-service \
                    --cluster ${cluster} \
                    --service ${service} \
                    --force-new-deployment
                    '''
                }
            }
        }
    }

    post {
        success {
            slackSend(
                channel: '#all-javacicdproject',
                color: 'good',
                message: "Build #${env.BUILD_NUMBER} succeeded and deployed successfully."
            )
        }

        failure {
            slackSend(
                channel: '#all-javacicdproject',
                color: 'danger',
                message: "Build #${env.BUILD_NUMBER} failed. Please check Jenkins logs."
            )
        }

        always {
            slackSend(
                channel: '#all-javacicdproject',
                color: 'warning',
                message: "Build #${env.BUILD_NUMBER} completed."
            )
        }
    }
}