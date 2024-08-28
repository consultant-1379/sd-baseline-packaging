#!/usr/bin/env bash

set -ex

# Download SO Baseline chart
if [[ -z "${SD_VERSION}" ]]; then
    echo "Error: SD_VERSION is not set"
    exit 1
fi

CHART_NAME=sd-$SD_VERSION.tgz
wget https://arm.epk.ericsson.se/artifactory/proj-orchestration-sd-helm/$CHART_NAME

# Create CSAR
docker build -t application-manager:1 .
docker run --rm \
    -v `pwd`:/build \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -w \
    /build application-manager:1 generate -hm $CHART_NAME -n sd-$SD_VERSION -s /build/scripts

echo "Files:"
ls -lah
