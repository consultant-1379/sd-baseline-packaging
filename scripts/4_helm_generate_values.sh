#!/usr/bin/env bash

####
# Generate pf_values.yml for installation.
####


# ingress_hostname, loadBalancerAddress, ecmUrl, ecmTenantId, ecmAuthHeader, enmUrl, enmUsername, enmPwd

usage="Usage: ./pf_helm_generate_values.sh path/to/images.txt.retagged ingress_hostname loadBalancerAddress ecmUrl ecmTenantId ecmAuthHeader enmUrl enmUsername enmPwd"

if [ -z ${1+x} ]; then
    echo "Path to retagged images list required."
    echo $usage
    exit 1
fi

if [ -z ${2+x} ]; then
    echo "Ingress hostname required."
    echo $usage
    exit 1
fi

if [ -z ${3+x} ]; then
    echo "Load Balancer Address required."
    echo $usage
    exit 1
fi

if [ -z ${4+x} ]; then
    echo "ECM URL required."
    echo $usage
    exit 1
fi

if [ -z ${5+x} ]; then
    echo "ECM Tenant ID required."
    echo $usage
    exit 1
fi

if [ -z ${6+x} ]; then
    echo "ECM Auth Header required."
    echo $usage
    exit 1
fi

if [ -z ${7+x} ]; then
    echo "ENM URL required."
    echo $usage
    exit 1
fi

if [ -z ${8+x} ]; then
    echo "ENM Username required."
    echo $usage
    exit 1
fi

if [ -z ${9+x} ]; then
    echo "ENM Password required."
    echo $usage
    exit 1
fi

images_retagged=$1
ingress_hostname=$2
load_balancer_address=$3
ecmUrl=$4
ecmTenantId=$5
ecmAuthHeader=$6
enmUrl=$7
enmUsername=$8
enmPwd=$9
values="pf_values.yml"

echo "Generating $values..."

rm -f $values

cat <<EOF >> $values
ingress: 
  hostname: $ingress_hostname
EOF

while read -r image
do
    name=$(echo "$image" | sed "s/^.*\/\(.*\):.*$/\1/")
    repository=$(echo "$image" | sed "s/^\(.*\):.*$/\1/")
    echo "Generating values for [$name]..."

    if [[ $name = "eric-data-coordinator-zk" ]]; then
        repository=$(echo "$image" | sed "s/^\(.*\)\/.*:.*$/\1/")
        cat <<EOF >> $values
$name:
  imageCredentials:
    repository: $repository
EOF
    elif [[ $name = "api-gateway" ]]; then
        cat <<EOF >> $values
$name:
  image:
    repository: $repository
  cluster:
    realm: http://$ingress_hostname
  forgerock:
    uri: http://$ecmUrl:8080/
    realm: $ecmTenantId
EOF
    elif [[ $name = "ocwf-micro" ]]; then
        cat <<EOF >> $values
$name:
  image:
    repository: $repository
  ecmConfig:
    ecmUrl: $ecmUrl
    tenantId: $ecmTenantId
    authHeader: $ecmAuthHeader
EOF
    elif [[ $name = "eric-data-message-bus-kf" ]]; then
        cat <<EOF >> $values
$name:
  image:
    repository: $repository
  persistence:
    storageClassName: default  
  external_access:
    enabled: true
    extHostName: $load_balancer_address
    
EOF
    else
        cat <<EOF >> $values
$name:
  image:
    repository: $repository
EOF

    fi
done < "$images_retagged"

echo "Done!"
