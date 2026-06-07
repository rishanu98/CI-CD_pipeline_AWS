# VProfile — Visualpathit VProfile Webapp

## Project Overview

VProfile is a Java-based web application (WAR) providing user profile and account management functionality. It uses Spring (MVC, Security, Data JPA) with Hibernate, and integrates with Elasticsearch, RabbitMQ and Memcached. The repository includes CI/CD pipelines, infrastructure provisioning scripts, and helper tooling for building, testing and deploying the application to AWS ECS.

## Architecture & Components

- **Backend:** Java 17, Spring Framework (web, webmvc, security, data-jpa), Hibernate
- **Persistence:** MySQL (connector present) for application data; SQL migrations/backups found under `src/main/resources/` (e.g. `accountsdb.sql`, `db_backup.sql`).
- **Search:** Elasticsearch client libraries integrated for search features.
- **Messaging:** RabbitMQ (`spring-rabbit`, `amqp-client`).
- **Caching:** Memcached (spymemcached).
- **Webapp:** Traditional JSP-based views under `src/main/webapp/WEB-INF/views/`.

## Tools & Technologies Used

- **Java 17** — language/runtime target (see `pom.xml`).
- **Maven** — build system (`pom.xml`, `mvn clean install`, plugins: war, jetty, jacoco).
- **Jetty** — local dev/test via `jetty-maven-plugin` (embedded run).
- **JUnit / Mockito** — unit testing frameworks.
- **JaCoCo** — code coverage reporting.
- **Elasticsearch** — search engine integration (client libs in `pom.xml`).
- **RabbitMQ** — messaging broker (Spring AMQP).
- **Memcached** — caching layer (spymemcached).
- **MySQL** — primary relational database.
- **Logback / Log4j** — logging frameworks.
- **Docker** — application containerization (Jenkinsfile builds Docker images).
- **AWS ECR / ECS** — container registry and orchestration target used in CI/CD.
- **Jenkins** — CI/CD server (pipeline defined in `Jenkinsfile`).
- **SonarQube** — static code analysis integration (Jenkins stage + `sonar-scanner`).
- **Nexus** — artifact repository provisioning scripts included.
- **Nginx** — reverse proxy (used in SonarQube provisioning script).
- **Vagrant** — local/VM provisioning (Vagrantfiles under `vagrant/`).
- **Bash scripts** — provisioning helpers in `userdata/` (e.g. `jenkins-setup.sh`, `nexus-setup.sh`, `sonar-setup.sh`).
- **Slack** — build notifications from Jenkins pipeline.

## Prerequisites (Developer)

- Java 17 (JDK) installed
- Maven 3.6+
- MySQL server (or Dockerized MySQL)
- Docker (for local image builds)
- (Optional) Vagrant + VirtualBox if using provided Vagrant provisioning

## Local Development — Quick Start

1. Build the project:

	 mvn clean install

2. Run locally with Jetty (for development):

	 mvn jetty:run

3. Access the webapp at: http://localhost:8080/

4. Database:

	 - Import the schema/sample data from `src/main/resources/accountsdb.sql` into your local MySQL instance.
	 - Update `src/main/resources/application.properties` with your DB credentials and connection URL.

## Running Tests & Coverage

- Run unit tests:

	mvn test

- Generate coverage report (JaCoCo is configured in `pom.xml`):

	mvn verify

Reports will be produced under `target/site/jacoco`.

## CI/CD (Jenkins) Overview

- The pipeline is defined in `Jenkinsfile` and implements the following stages:
	- Build (`mvn clean install`), archive WAR artifacts
	- Test (`mvn test`)
	- Static analysis (SonarQube via `sonar-scanner`)
	- Docker image build (expects image context at `./Docker-files/app/multistage/`)
	- Push image to AWS ECR
	- Deploy to AWS ECS (updates service to force new deployment)
	- Slack notifications for success/failure/completion

## Docker / AWS Deployment

- Jenkins builds images and pushes to AWS ECR using credentials configured in the pipeline.
- ECS is used to run the containers; the `Jenkinsfile` calls `aws ecs update-service` to trigger deployments.

## Docker (local) — Build, Run & Push

This project uses Docker in CI and can be built and run locally. The Jenkins pipeline expects the Docker build context at `./Docker-files/app/multistage/` (multi-stage Dockerfile).

1) Build locally (from repo root):

	docker build -t vprofile-app:local ./Docker-files/app/multistage/

2) Run locally (adjust port as needed):

	docker run --rm -p 8080:8080 vprofile-app:local

3) Tag and push to AWS ECR (example for `us-east-1` — replace `<aws-account-id>` and `region`):

	aws ecr create-repository --repository-name vprofile-app --region us-east-1 || true
	aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <aws-account-id>.dkr.ecr.us-east-1.amazonaws.com
	docker tag vprofile-app:local <aws-account-id>.dkr.ecr.us-east-1.amazonaws.com/vprofile-app:latest
	docker push <aws-account-id>.dkr.ecr.us-east-1.amazonaws.com/vprofile-app:latest

Notes:
- Jenkins tags images using the build number (`${BUILD_NUMBER}`) and also pushes a `latest` tag.
- If `./Docker-files/app/multistage/` is missing, add a Dockerfile there or update the `Jenkinsfile` to point to your Docker context.


## Provisioning & Other Scripts

- `userdata/jenkins-setup.sh` — installs Jenkins server (Ubuntu/Debian).
- `userdata/nexus-setup.sh` — installs and configures Nexus repository.
- `userdata/sonar-setup.sh` — installs SonarQube, PostgreSQL, Nginx and configures system settings.
- `vagrant/` — Vagrant configurations and provisioning scripts for different environments (Mac/Win).

## Important Paths

- Application properties: `src/main/resources/application.properties`
- Database scripts: `src/main/resources/accountsdb.sql`, `src/main/resources/db_backup.sql`
- Web views: `src/main/webapp/WEB-INF/views/`
- CI Pipeline: `Jenkinsfile`

## Contributing

- Fork the repository and create feature branches.
- Follow code style used in the project and include unit tests for new logic.
- Run `mvn test` and ensure SonarQube checks pass before submitting a PR.

## Troubleshooting

- If Jetty binding fails, ensure port 8080 is free or change the port in the Jetty plugin configuration.
- SonarQube: check `sonar-setup.sh` for system requirements (Java 21 for recent SonarQube releases).

## Next Steps / Recommendations

- Add a `Docker-files` directory if the Jenkins pipeline's Docker context is missing.
- Add a `deploy` directory containing ECS task and service definitions (CloudFormation/terraform) for repeatable infra.

---

If you want, I can: (1) add example `docker` and `ecs` configurations, (2) create a CONTRIBUTING.md, or (3) commit and push these changes to the remote.

