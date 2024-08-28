#!/usr/bin/env bash

####
# Load PF docker images.
####


if [ -z ${1+x} ]; then
    echo "Path to tar with docker images required."
    echo "Usage: ./1_docker_load.sh path/to/docker.tar"
    exit 1
fi

docker_images_tar=$1

echo "Loading [$docker_images_tar]..."
sudo docker load --input $docker_images_tar

echo "Done!"

