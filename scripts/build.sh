#! /bin/bash

  set -e
  set -u
  set -o pipefail

  # Build Java App
  mvn clean deploy --no-transfer-progress