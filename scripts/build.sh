#! /bin/bash

  set -e
  set -u
  set -o pipefail

  # Build Java App
  mvn -DskipTests=true package --no-transfer-progress 

  # Push container to ECR in shared services
  REPOSITORY_URI="615961246879.dkr.ecr.us-east-1.amazonaws.com/warner/looney/roadrunner"
  COMMIT_HASH=$(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | cut -c 1-7)
  IMAGE_TAG=${COMMIT_HASH:=latest}

  $(aws ecr get-login --region us-east-1 --no-include-email)
  docker build -t $REPOSITORY_URI:latest .
  docker tag $REPOSITORY_URI:latest $REPOSITORY_URI:$IMAGE_TAG
  docker push $REPOSITORY_URI:latest
  docker push $REPOSITORY_URI:$IMAGE_TAG