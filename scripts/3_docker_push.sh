#!/usr/bin/env bash

####
# Push retagged images.
####

if [ -z ${1+x} ]; then
    echo "Path to retagged images list required."
    echo "Usage: ./3_docker_push.sh path/to/images.txt.retagged"
    exit 1
fi

images_retagged=$1

while read -r image
do
    echo "Pushin [$image]..."
    sudo docker push $image
done < "$images_retagged"

