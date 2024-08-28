#!/usr/bin/env bash

####
# Retag PF docker image with appropriate registry.
####

if [ -z ${1+x} ]; then
    echo "Path to images list required."
    echo "Usage: ./2_docker_retag.sh path/to/images.txt registry:5000"
    exit 1
fi

if [ -z ${2+x} ]; then
    echo "Registry location required."
    echo "Usage: ./2_docker_retag.sh path/to/images.txt registry:5000"
    exit 1
fi

images=$1
registry=$2
images_retagged=$images.retagged

rm -f $images_retagged

echo "Writing retagged image names to $images_retagged"

while read -r currentName
do
    newName=$(echo $currentName | sed "s/^armdocker\.rnd\.ericsson\.se\(.*\)$/$2\1/")

    echo "Retagging [$currentName] to [$newName]"
    sudo docker tag $currentName $newName
    echo $newName >> $images_retagged
done < "$images"

echo "Done!"

