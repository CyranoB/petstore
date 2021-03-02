#! /bin/bash

set -e
set -u
set -o pipefail

wget -q https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-4.6.0.2311.zip
unzip -qq sonar-scanner-cli-4.6.0.2311.zip
export SCANNER="sonar-scanner-4.6.0.2311/lib/sonar-scanner-cli-4.6.0.2311.jar"
pip3 -q install truffleHog


export SONAR_TOKEN=$(aws secretsmanager get-secret-value --secret-id SONAR_TOKEN --query SecretString --output text)

export sq_prj=$(aws ssm get-parameter --name "/warner/looney/roadrunner/sonar/project" --query Parameter.Value --output text)
export sq_org=$(aws ssm get-parameter --name "/warner/looney/roadrunner/sonar/org" --query Parameter.Value --output text)
export sq_url=$(aws ssm get-parameter --name "/warner/looney/roadrunner/sonar/url" --query Parameter.Value --output text)


# Build Java App
mvn -Dcheckstyle.skip -DskipTests=true package --no-transfer-progress 
java -jar $SCANNER -Dsonar.projectKey=$sq_prj -Dsonar.organization=$sq_org -Dsonar.host.url=https://sonarcloud.io -Dsonar.qualitygate.wait=true -Dsonar.java.binaries=target/classes

# Push container to ECR in shared services
REPOSITORY_URI="615961246879.dkr.ecr.us-east-1.amazonaws.com/warner/looney/roadrunner"
COMMIT_HASH=$(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | cut -c 1-7)
IMAGE_TAG=${COMMIT_HASH:=latest}

$(aws ecr get-login --region us-east-1 --no-include-email)
docker build -t $REPOSITORY_URI:latest .
docker tag $REPOSITORY_URI:latest $REPOSITORY_URI:$IMAGE_TAG
docker push $REPOSITORY_URI:latest
docker push $REPOSITORY_URI:$IMAGE_TAG