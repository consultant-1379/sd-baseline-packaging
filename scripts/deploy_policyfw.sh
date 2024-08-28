#!/usr/bin/env bash

# ingress_hostname, loadBalancerAddress, ecmUrl, ecmTenantId, ecmAuthHeader, enmUrl, enmUsername, enmPwd, KbIngressHostname

usage="Usage: ./deploy_policyfw.sh ingress_hostname loadBalancerAddress ecmUrl ecmTenantId ecmAuthHeader enmUrl enmUsername enmPwd KbIngressHostname"

if [ -z ${1+x} ]; then
    echo "Ingress hostname required."
    echo $usage
    exit 1
fi

if [ -z ${2+x} ]; then
    echo "Load Balancer Address required."
    echo $usage
    exit 1
fi

if [ -z ${3+x} ]; then
    echo "ECM URL required."
    echo $usage
    exit 1
fi

if [ -z ${4+x} ]; then
    echo "ECM Tenant ID required."
    echo $usage
    exit 1
fi

if [ -z ${5+x} ]; then
    echo "ECM Auth Header required."
    echo $usage
    exit 1
fi

if [ -z ${6+x} ]; then
    echo "ENM URL required."
    echo $usage
    exit 1
fi

if [ -z ${7+x} ]; then
    echo "ENM Username required."
    echo $usage
    exit 1
fi

if [ -z ${8+x} ]; then
    echo "ENM Password required."
    echo $usage
    exit 1
fi

if [ -z ${9+x} ]; then
    echo "Kb ingress hostname required."
    echo $usage
    exit 1
fi

images_retagged="../Files/images.txt.retagged"
ingress_hostname=$1
loadBalancerAddress=$2
ecmUrl=$3
ecmTenantId=$4
ecmAuthHeader=$5
enmUrl=$6
enmUsername=$7
enmPwd=$8
KbIngressHostname=$9
policyfwChart=../Definitions/otherTemplates/*.tgz
values="policyfw_values.yml"
# Generating policyfw_values.yml in the script below


####
# Verify environment
####
echo "Verifing environment"
./0_verify_environment.sh


####
# Load PF docker images.
####
./1_docker_load.sh ../Files/images/docker.tar


####
# Retag PF docker image with appropriate registry.
####
./2_docker_retag.sh ../Files/images.txt k8s-registry.eccd.local


####
# Push retagged images.
####
./3_docker_push.sh ../Files/images.txt.retagged


####
# Generate pf_values.yml for installation.
####

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

    if [[ $name = "data-coordinator-zk-3.4.10" ]]; then
        repository=$(echo "$image" | sed "s/\.local.*/\.local/")
        cat <<EOF >> $values
eric-data-coordinator-zk:
  global:
    registry:
      url: $repository
EOF

    elif [[ $name = "eric-data-document-database-pg" ]]; then
      repository=$(echo "$image" | sed "s/\.local.*/\.local/")
      cat <<EOF >> $values
eric-data-document-database-pg:
  imageCredentials:
    repository: $repository/proj-document-database-pg/data
EOF

     elif [[ $name = "eric-log-shipper" ]]; then
      repository=$(echo "$image" | sed "s/\.local.*/\.local/")
      cat <<EOF >> $values
eric-log-shipper:
  global:
    registry:
      url: $repository
EOF

     elif [[ $name = "eric-data-search-engine" ]]; then
      repository=$(echo "$image" | sed "s/\.local.*/\.local/")
      cat <<EOF >> $values
eric-data-search-engine:
  global:
    registry:
      url: $repository
EOF

     elif [[ $name = "adp-gs-branding" ]]; then
      repository=$(echo "$image" | sed "s/\.local.*/\.local/")
      cat <<EOF >> $values
adp-gs-branding:
  global:
    registry:
      url: $repository
EOF

     elif [[ $name = "eric-log-transformer" ]]; then
      repository=$(echo "$image" | sed "s/\.local.*/\.local/")
      cat <<EOF >> $values
eric-log-transformer:
  global:
    registry:
      url: $repository
EOF

     elif [[ $name = "eric-data-visualizer-kb" ]]; then
      repository=$(echo "$image" | sed "s/\.local.*/\.local/")
      cat <<EOF >> $values
eric-data-visualizer-kb:
  global:
    registry:
      url: $repository
  ingress:
    enabled: true
    hosts:
      - $KbIngressHostname
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
  enmConfig:
     url: $enmUrl
     username: $enmUsername
     password: $enmPwd
EOF

    elif [[ $name = "message-bus-kf-1.0.1" ]]; then
        repository=$(echo "$image" | sed "s/\.local.*/\.local/")
        cat <<EOF >> $values
eric-data-message-bus-kf:
  global:
    registry:
      url: $repository
  external_access:
    enabled: true
    extHostName: $loadBalancerAddress
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


####
# Helm Install PF.
####

helm \
    upgrade \
    --debug \
    --install \
    --wait \
    --timeout 1200 \
    --namespace policyfw \
    --values $values \
    policyfw $policyfwChart
