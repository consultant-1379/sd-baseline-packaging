#!/usr/bin/env bash

####
# Helm Install PF.
####

if [ -z ${1+x} ]; then
    echo "Path to PF chart tar required."
    echo "Usage: ./5_helm_install.sh path/to/pf.tgz path/to/pf_values.yml"
    exit 1
fi

if [ -z ${2+x} ]; then
    echo "Path to values required."
    echo "Usage: ./5_helm_install.sh path/to/pf.tgz path/to/pf_values.yml"
    exit 1
fi

pf_chart=$1
values=$2

helm \
    upgrade \
    --debug \
    --install \
    --wait \
    --timeout 1200 \
    --namespace pf \
    --values $values \
    pf $pf_chart