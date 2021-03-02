#! /bin/bash

  set -e
  set -u
  set -o pipefail

  # Build Java App
  mvn -DskipTests=true package --no-transfer-progress 