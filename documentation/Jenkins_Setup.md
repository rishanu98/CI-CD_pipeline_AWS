1. Maven - 3.9.9 (tested on that)
2. JDK - 17 or 21
    Install jdk 17 on machine and provide the path in tools. Make sure to install the JDK plugin in jenkins so that we can provide the path in tools section.
    Tool means combination of plugin and the actual tool. The actual tool can be directly installed through the tool section or on the machine directly
    - command : apt install openjdk-17-jdk -y
3. Git : If git is installed as a tool on jenkins server if we directly use SCM by providing repo URL and add credentials
         In build step we can use MAVEN3.9 because we already installed it using tools. if we don't get the option for any tool to install via tools then go for script
         After build step we get the artifact as *.var format
4. Steps to setup Project on jenkins
    1. Jenkins setup
    2. Nexus setup
    3. Sonarqube setup - Sonnarqube scanner version - 8.0.1.6346
    4. Security Group (jenkins sg should allow sonarqube access so that it can send the analysis results using webhooks)
    5.  Plugins -    - Nexus Artifact Uploader, Sonarqube, Git, Pipeline Maven Integration, Build_TimeStamp_Plugin (optional), Docker, aws steps, AWS SDK, amazon ecr
                    - AWS Credentials Plugin
                    - Kubernetes Plugin
                    - Kubernetes CLI Plugin
                    - Kubernetes Credentials
                    - Stage view
                    - To interact with an EKS cluster from Jenkins, you typically need to AWS Credentials Plugin
    6. Add webhook in sonarqube to respond back the analysis result to jenkins server Ref : https://dev.to/rahulxsingh/sonarqube-jenkins-integration-pipeline-setup-34d5
    7.  Install docker and Docker Pipeline Plugin, docker-build-step plugin
        add jenkins group to docker group with proper permission. if get permisson denied for connecting to socket Ref: https://stackoverflow.com/questions/51342810/how-to-fix-dial-unix-var-run-docker-sock-connect-permission-denied-when-gro
        Change the permissions of docker socket to be able to connect to the docker daemon
        sudo chmod 660 /var/run/docker.sock
    8. Add aws cli - sudo snap install aws-cli --classic
       Create an IAM User with permissions to connect with ECR and ECS to upload image to docker registry which is ECR in our case
       

