pipeline {
    agent any

    environment {
        registryUrl = "https://471112617705.dkr.ecr.us-east-1.amazonaws.com"
        imageName   = "471112617705.dkr.ecr.us-east-1.amazonaws.com/vprofile-app"
        awsCred     = "awscred"
        cluster     = "vprofileapp"
        service     = "vproappservice"
        region      = "us-east-1"
    }

    tools {
        maven 'MAVEN3.9'
        jdk 'JDK17'
    }

    stages {

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
                scannerHome = tool 'sonar-scanner'
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