#!/bin/bash

# Open a new file descriptor that redirects to stdout:
exec 3>&1

log () {
    echo "$1" 1>&3
}

data_usage_agreement_exists () {
  log "Veriyfing if Data Usage Agreement ${1} Exists"
  paylod=$(curl -s -X 'GET' \
    "${DATACONTRACT_MANAGER_HOST}/api/datausageagreements/${1}" \
    --header "x-api-key: ${DATACONTRACT_MANAGER_API_KEY}" \
    --header "content-type: application/json" | jq -r '.id')
  
  if [[ $paylod == ${1} ]]; then
    log "Data Contract ${1} Exists"
    echo 1
  else
    log "Data Contract ${1} Does Not Exist"
    echo 0
  fi
}

data_usage_agreement_create () {
  log "Creating Data Usage Agreement ${1}"
  curl -s -X 'PUT' \
    "${DATACONTRACT_MANAGER_HOST}/api/datausageagreements/${1}" \
    --header "x-api-key: ${DATACONTRACT_MANAGER_API_KEY}" \
    --header "content-type: application/json" \
    --data "$(cat ${2} | yq)"
}

data_contract_exists () {
  log "Veriyfing if Data Contract ${1} Exists"
  paylod=$(curl -s -X 'GET' \
    "${DATACONTRACT_MANAGER_HOST}/api/datacontracts/${1}" \
    --header "x-api-key: ${DATACONTRACT_MANAGER_API_KEY}" \
    --header "content-type: application/json" | jq -r '.id')
  
  if [[ $paylod == ${1} ]]; then
    log "Data Contract ${1} Exists"
    echo 1
  else
    log "Data Contract ${1} Does Not Exist"
    echo 0
  fi
}

data_contract_create () {
  log "Creating Data Contract ${1}"
  curl -s -X 'PUT' \
    "${DATACONTRACT_MANAGER_HOST}/api/datacontracts/${1}" \
    --header "x-api-key: ${DATACONTRACT_MANAGER_API_KEY}" \
    --header "content-type: application/json" \
    --data "$(cat ${2} | yq)"
}

data_product_exists () {
  log "Veriyfing if Data Product ${1} Exists"
  paylod=$(curl -s -X 'GET' \
    "${DATACONTRACT_MANAGER_HOST}/api/dataproducts/${1}" \
    --header "x-api-key: ${DATACONTRACT_MANAGER_API_KEY}" \
    --header "content-type: application/json" | jq -r '.id')
  
  if [[ $paylod == ${1} ]]; then
    log "Data Product ${1} Exists"
    echo 1
  else
    log "Data Product ${1} Does Not Exist"
    echo 0
  fi
}

data_product_create () {
  log "Creating Data Product ${1}"
  curl -s -X 'PUT' \
    "${DATACONTRACT_MANAGER_HOST}/api/dataproducts/${1}" \
    --header "x-api-key: ${DATACONTRACT_MANAGER_API_KEY}" \
    --header "content-type: application/json" \
    --data "$(cat ${2} | yq)"
}

for data_contract in metadata/output/data_contracts/*.yaml; do
  [ -e ${data_contract} ] || continue
  
  data_contract_id=$(cat ${data_contract} | yq -r '.id')
  exists=$(data_contract_exists "${data_contract_id}")
  if [ "${exists}" == "0" ]; then
    log "Evaluating diff between code repo vs DCM."
    ## TODO: Build Smart Comparison
  fi
  data_contract_create "${data_contract_id}" "${data_contract}"
done


for data_product in metadata/output/data_products/*.yaml; do
  data_product_id=$(cat ${data_product} | yq -r '.id')
  exists=$(data_product_exists "${data_product_id}")
  if [ "${exists}" == "0" ]; then
    log "Evaluating diff between code repo vs DCM."
    ## TODO: Build Smart Comparison
  fi
  data_product_create "${data_product_id}" "${data_product}"
done

for data_usage_agreement_dir in metadata/output/data_usage_agreements/*; do
  for data_usage_agreement in ${data_usage_agreement_dir}/*.yaml; do
    data_usage_agreement_id=$(echo "$(yq -r '.id' ${data_usage_agreement})")
    exists=$(data_usage_agreement_exists "${data_usage_agreement_id}")
    if [ "${exists}" == "0" ]; then
      data_usage_agreement_create "${data_usage_agreement_id}" "${data_usage_agreement}"
    fi
  done
done