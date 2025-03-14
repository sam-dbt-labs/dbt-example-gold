#!/bin/bash

# Open a new file descriptor that redirects to stdout:
exec 3>&1

log () {
    echo "$1" 1>&3
}

generate_uuid () {
  echo "$(awk -v seed=$RANDOM 'BEGIN { srand(seed); printf( "%08x-%04x-%04x-%04x-%04x%04x%04x", rand()*4294967295, rand()*65535, rand()*65535, rand()*65535, rand()*65535, rand()*65535, rand()*65535) }')"
}

get_data_products () {
  #log "Retrieving Page ${1} of DCM Data Products"
  response=$(curl -s -X 'GET' \
    "${DATACONTRACT_MANAGER_HOST}/api/dataproducts?p=${1}" \
    --header "x-api-key: ${DATACONTRACT_MANAGER_API_KEY}" \
    --header "content-type: application/json")
  
  echo "${response}"
}

# List of elements to search for
INPUT_CONTRACT_MAP="{}"
for input in metadata/input/data_contracts/*.yaml; do
  input_id=$(yq -r '.id' ${input})

  #log "Adding ${input_id} to search list"
  INPUT_CONTRACT_MAP=$(echo "${INPUT_CONTRACT_MAP}" | jq --arg id ${input_id} '.[$id] |= {}')
done

INPUT_CONTRACT_LENGTH=$(echo "${INPUT_CONTRACT_MAP}" | jq -r 'keys | length')
DCM_COUNT=0
# Initialize a counter to keep track of found elements
FOUND_COUNT=0

while [ $FOUND_COUNT -lt $((INPUT_CONTRACT_LENGTH)) ]; do
  DCM_RESPONSE=$(get_data_products ${DCM_COUNT})

  if [[ -z "${DCM_RESPONSE}" ]]; then
    echo "DCM Response Empty"
    break
  fi

  log "Processing Page ${DCM_COUNT} of DCM Data Products"
  PAGE_LENGTH=$(echo "${DCM_RESPONSE}" | jq -r '. | length')
  for ((i=0; i < PAGE_LENGTH; i++)); do

    log "Processing Data Product ${i}"
    OUTPUT_PORTS=$(echo "${DCM_RESPONSE}" | jq -r --argjson index $((i)) '.[$index].outputPorts')
    PORTS_LENGTH=$(echo "${OUTPUT_PORTS}" | jq -r '. | length')
    for ((j=0; j < PORTS_LENGTH; j++)); do

      log "Processing Output Port ${j}"
      OUTPUT_PORT=$(echo "${OUTPUT_PORTS}" | jq -r --argjson index $((j)) '.[$index]')
      if [ "$(echo "${OUTPUT_PORT}" | jq -r 'has("dataContractId")')" == "true" ]; then
        for k in $(echo "${INPUT_CONTRACT_MAP}" | jq -r 'keys | .[]'); do
          if [ "$(echo "${OUTPUT_PORT}" | jq -r --arg contractId ${k} '.dataContractId == $contractId')" == "true" ]; then
            log "Found a match for contract ${k} and output port ${j}"
            INPUT_CONTRACT_MAP=$(echo "${INPUT_CONTRACT_MAP}" | \
              jq --arg contractId "${k}" \
                 --arg outputPortId "$(echo "${OUTPUT_PORT}" | jq -r '.id')" \
                 --argjson outputPortName "$(echo "${OUTPUT_PORT}" | jq '.name')" \
                 --arg productId "$(echo "${DCM_RESPONSE}" | jq -r --argjson index ${i} '.[$index].id')" \
                  '.[$contractId] += { 
                    ($outputPortId) : {
                      "outputPortName": $outputPortName,
                      "productId": $productId
                    }
                  }')
              FOUND_COUNT=$((FOUND_COUNT + 1))
              continue
          fi
        done
      fi
    done
  done

  DCM_COUNT=$((DCM_COUNT + 1))

done

CONSUMER_PRODUCT_ID=$(cat metadata/output/data_products/source.yaml | yq -r '.id')

for contract in $(echo "${INPUT_CONTRACT_MAP}" | jq -r 'keys | .[]'); do
  [ ! -d "metadata/output/data_usage_agreements/${contract}" ] && mkdir "metadata/output/data_usage_agreements/${contract}"

  for port in $(echo "${INPUT_CONTRACT_MAP}" | jq -r --arg contractId ${contract} '.[$contractId] | keys | .[]'); do
    if [ ! -f "metadata/output/data_usage_agreements/${contract}/${port}.yaml" ]; then
      log "Creating Usage Agreement for contract ${contract} with output port ${port}"
      producer_product_id="$(echo "${INPUT_CONTRACT_MAP}" | jq -r --arg c ${contract} --arg p ${port} '.[$c] | .[$p] | .productId')"
      producer_port_name="$(echo "${INPUT_CONTRACT_MAP}" | jq -r --arg c ${contract} --arg p ${port} '.[$c] | .[$p] | .outputPortName')"

      #echo "port=${port}"
      #echo "contract=${contract}"
      #echo "producer_product_id=${producer_product_id}"
      #echo "producer_port_name=${producer_port_name}"

      echo "{}" |
        jq --arg usageAgreementId "$(echo $(generate_uuid))" \
          --arg contractId "${contract}" \
          --arg startDate "$(date '+%Y-%m-%d')" \
          --arg consumerProductId "${CONSUMER_PRODUCT_ID}" \
          --arg producerProductId "${producer_product_id}" \
          --arg producerPortId "${port}" \
          --arg producerPortName "${producer_port_name}" \
          '
            .id += $usageAgreementId |
            .info += {
              "purpose": "Producer Initiated Usage Agreement with dbt",
              "description": "Usage agreement for $producerPortName with $contractId",
              "startDate": $startDate
            } |
            .provider += {
              "dataProductId": $producerProductId,
              "outputPortId": $producerPortId,
              "teamId": "enabling-team"
            } |
            .consumer += {
              "dataProductId": $consumerProductId,
              "teamId": "enabling-team"
            } |
            .tags += [
              "POC"
            ]
          ' | \
          yq --yaml-output '.' > metadata/output/data_usage_agreements/${contract}/${port}.yaml
    fi
  done
done