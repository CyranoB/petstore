#! /bin/bash

set -e
set -u
set -o pipefail

# Install scaning tools
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/master/contrib/install.sh | sh -s -- -b /usr/local/bin
wget -q https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-4.6.0.2311.zip
unzip -qq sonar-scanner-cli-4.6.0.2311.zip
SCANNER="sonar-scanner-4.6.0.2311/lib/sonar-scanner-cli-4.6.0.2311.jar"
pip3 -q install truffleHog
export DOCKER_BUILDKIT=1

# Import prameters from SSM
#SONAR_TOKEN=$(aws secretsmanager get-secret-value --secret-id SONAR_TOKEN --query SecretString --output text)
SONAR_TOKEN=$(aws ssm get-parameter --name "/warner/looney/roadrunner/sonar/token" --query Parameter.Value --output text --with-decryption)
sq_prj=$(aws ssm get-parameter --name "/warner/looney/roadrunner/sonar/project" --query Parameter.Value --output text)
sq_org=$(aws ssm get-parameter --name "/warner/looney/roadrunner/sonar/org" --query Parameter.Value --output text)
sq_url=$(aws ssm get-parameter --name "/warner/looney/roadrunner/sonar/url" --query Parameter.Value --output text)
REPOSITORY_URI=$(aws ssm get-parameter --name "/warner/looney/roadrunner/repository_uri" --query Parameter.Value --output text)

# Build Java App
mvn -Dcheckstyle.skip -Dlogging.level.org.springframework=OFF -Dlogging.level.root=OFF -Dformat=JUNIT -Dspring.main.banner-mode=off --no-transfer-progress package org.owasp:dependency-check-maven:check

# SonarQube scan. Fails build on failed quality gate.
java -jar $SCANNER -Dsonar.projectKey=$sq_prj -Dsonar.organization=$sq_org -Dsonar.host.url=$sq_url -Dsonar.qualitygate.wait=true -Dsonar.java.binaries=target/classes

# Secutiry scanning 
# Build locally
docker build -o .dockerout .
# Security scan local image to build report
trivy --quiet filesystem  -f template --template "@sripts/trivy-junit.tpl" -o target/findings.xml --exit-code 0 --severity CRITICAL,HIGH,MEDIUM  .dockerout
# Fails build on high and critical vulnerabilities
trivy --quiet filesystem --exit-code 1 --severity HIGH,CRITICAL .dockerout


# Push container to ECR in shared services
COMMIT_HASH=$(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | cut -c 1-7)
IMAGE_TAG=${COMMIT_HASH:=latest}
$(aws ecr get-login --region $AWS_REGION --no-include-email)
docker build -t $REPOSITORY_URI:latest .
docker tag $REPOSITORY_URI:latest $REPOSITORY_URI:$IMAGE_TAG
docker push $REPOSITORY_URI:latest
docker push $REPOSITORY_URI:$IMAGE_TAG