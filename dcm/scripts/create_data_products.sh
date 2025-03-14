#!/bin/bash

# Open a new file descriptor that redirects to stdout:
exec 3>&1

log () {
    echo "$1" 1>&3
}

GH_REPO=$(gh repo view --json url -q '.url') || GH_REPO=localhost

if [[ ! -f metadata/output/data_products/source.yaml ]]; then
  echo "{}" | \
    jq -r \
      --arg gh_repo ${GH_REPO} \
      '
      .dataProductSpecification += "0.0.1" |
      .id += "urn:dataproduct:project:jaffle-shop:dbt:jaffle-shop-output" |
        
      .info += {
        "title": "dbt Jaffle Shop Output",
        "description": "Example Jaffle Shop OUTPUT Data provided by dbt/ created by dbt seed.",
        "owner": "enabling-team",
        "status": "development",
        "archetype": "consumer-aligned",
        "maturity": "managed"
      } |

      .outputPorts += [] |
        
      .tags += [
        "POC",
        "PROCESS"
      ] |

      .links += {
        "documentation": "$gh_repo/README.md",
        "catalog": "https://catalog.example.com/search/search-queries/",
        "repository": "$gh_repo"
      }
      ' > metadata/output/data_products/source.json

  yq --yaml-output '.' metadata/output/data_products/source.json > metadata/output/data_products/source.yaml
fi

for output in metadata/output/data_contracts/*.yaml; do
  output_id=$(yq -r '.id' ${output})
  for output_server in $(yq -r '.servers | keys[]' ${output}); do
    output_server_spec=$(yq -r --arg serverName ${output_server} '.servers | .[$serverName]' ${output})
    output_server_type=$(echo "${output_server_spec}" | jq -r '.type')

    if [ $(jq --arg id "${output_id}-${output_server_type}" '.outputPorts | length' metadata/output/data_products/source.json) -eq 0 ] || 
       [ -z "$( jq --arg id "${output_id}-${output_server_type}" '.outputPorts[] | select(.id == $id)' metadata/output/data_products/source.json)" ] ; then
      if [ "${output_server_type}" == "databricks" ]; then
        log "Adding Data Contract Output Port for ${output_id} with Server ${output_server_type}"
        cat metadata/output/data_products/source.json | \
          jq -r \
            --arg outputId "${output_id}-${output_server_type}" \
            --arg id "${output_id}" \
            --arg title "$(yq -r '.info.title' $output)" \
            --arg description "$(yq -r '.info.description' $output)" \
            --arg host "$(echo "${output_server_spec}" | jq -r '.host')" \
            --arg catalog "$(echo "${output_server_spec}" | jq -r '.catalog')" \
            --arg schema "$(echo "${output_server_spec}" | jq -r '.schema')" \
            '.outputPorts += [{
                "id": $outputId,
                "name": $title,
                "description": $description,
                "dataContractId": $id,
                "autoApprove": false,
                "containsPii": false,
                "type": "databricks",
                "server": {
                  "host": $host,
                  "catalog": $catalog,
                  "schema": $schema
                }
            }]' > metadata/output/data_products/source.json
      elif [ "${output_server_type}" == "snowflake" ]; then
        log "Adding Data Contract Output Port for ${output_id} with Server ${output_server_type}"
        cat metadata/output/data_products/source.json | \
          jq -r \
            --arg outputId "${output_id}-${output_server_type}" \
            --arg id "${output_id}" \
            --arg title "$(yq -r '.info.title' ${output})" \
            --arg description "$(yq -r '.info.description' ${output})" \
            --arg account "$(echo "${output_server_spec}" | jq -r '.account')" \
            --arg database "$(echo "${output_server_spec}" | jq -r '.database')" \
            --arg schema "$(echo "${output_server_spec}" | jq -r '.schema')" \
            '.outputPorts += [{
                "id": $outputId,
                "name": $title,
                "description": $description,
                "dataContractId": $id,
                "autoApprove": false,
                "containsPii": false,
                "type": "snowflake",
                "server": {
                  "account": $account,
                  "database": $database,
                  "schema": $schema
                }
            }]' > metadata/output/data_products/source.json
      fi
    fi
  done
done

yq --yaml-output '.' metadata/output/data_products/source.json > metadata/output/data_products/source.yaml