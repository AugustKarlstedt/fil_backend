#!/bin/bash

set -e

# ENVIRONMENT VARIABLE OPTIONS
# PREBUILT_SERVER_TAG: The tag of the prebuilt Triton server image to test
# PREBUILT_TEST_TAG: The tag of the prebuilt test image to run tests in
# LOG_DIR: Host directory for storing logs
# NV_DOCKER_ARGS: Docker arguments for controlling GPU access
# BUILDPY: 1 to use Triton's build.py script for server build

REPO_DIR=$(cd $(dirname $0)/../../; pwd)
QA_DIR="${REPO_DIR}/qa"
MODEL_DIR="${QA_DIR}/L0_e2e/model_repository"
CPU_MODEL_DIR="${QA_DIR}/L0_e2e/cpu_model_repository"
BUILDPY=${BUILDPY:-0}

# Check if test or base images need to be built and do so if necessary
if [ -z $PREBUILT_SERVER_TAG ]
then
  export SERVER_TAG=triton_fil
else
  export PREBUILT_IMAGE="$PREBUILT_SERVER_TAG"
  export SERVER_TAG="$PREBUILT_SERVER_TAG"
fi
if [ -z $PREBUILT_TEST_TAG ]
then
  export TEST_TAG=triton_fil_test
  echo "Building Docker images..."
  if [ $BUILDPY -eq 1 ]
  then
    $REPO_DIR/build.sh --buildpy
  else
    $REPO_DIR/build.sh
  fi
else
  export TEST_TAG="$PREBUILT_TEST_TAG"
fi
export TEST_TAG=triton_fil_test

# Set up directory for logging
if [ -z $LOG_DIR ]
then
  LOG_DIR="${QA_DIR}/logs"
fi
if [ ! -d "${LOG_DIR}" ]
then
  mkdir -p "${LOG_DIR}"
fi
LOG_DIR="$(readlink -f $LOG_DIR)"

DOCKER_ARGS="-v ${LOG_DIR}:/qa/logs"

if [ -z $NV_DOCKER_ARGS ]
then
  if [ -z $CUDA_VISIBLE_DEVICES ]
  then
    DOCKER_ARGS="$DOCKER_ARGS --gpus all"
  else
    DOCKER_ARGS="$DOCKER_ARGS --gpus $CUDA_VISIBLE_DEVICES"
  fi
else
  DOCKER_ARGS="$DOCKER_ARGS $NV_DOCKER_ARGS"
fi

echo "Generating example models..."
docker run \
  -e RETRAIN=1 \
  -e OWNER_ID=$(id -u) \
  -e OWNER_GID=$(id -g) \
  $DOCKER_ARGS \
  -v "${MODEL_DIR}:/qa/L0_e2e/model_repository" \
  -v "${CPU_MODEL_DIR}:/qa/L0_e2e/cpu_model_repository" \
  $TEST_TAG \
  bash -c 'conda run -n triton_test /qa/generate_example_models.sh'

echo "Running tests..."
docker run \
  $DOCKER_ARGS \
  -v "${MODEL_DIR}:/qa/L0_e2e/model_repository" \
  -v "${CPU_MODEL_DIR}:/qa/L0_e2e/cpu_model_repository" \
  --rm $TEST_TAG
