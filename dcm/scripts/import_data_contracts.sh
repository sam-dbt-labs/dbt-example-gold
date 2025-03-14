#!/bin/bash

source .venv/bin/activate

if [ ! -f metadata/output/data_contracts/output_calendar.yaml ]; then
  datacontract import \
  --format dbt \
  --source dbt/target/manifest.json \
  --dbt-model calendar \
  --template ./enablement_team_contract_template.yaml \
  --output metadata/output/data_contracts/output_calendar.yaml
  
  yq -i --yaml-output \
    --arg version $(date '+%Y.%m.%d') \
    '
      .id |= "urn:datacontract:project:jaffle-shop:dbt:output-model:calendar" |
      .info.title |= "Jaffle Shop OUTPUT Calendar Data Contract" |
      .info.description |= "Data Contract for Example Jaffle Shop OUTPUT Calendar Data provided by Mars/ created by dbt build." |
      .info.version |= $version
    ' \
    metadata/output/data_contracts/output_calendar.yaml
fi

if [ ! -f metadata/output/data_contracts/output_sales_finance_pl.yaml ]; then
  datacontract import \
  --format dbt \
  --source dbt/target/manifest.json \
  --dbt-model sales_finance_pl \
  --template ./enablement_team_contract_template.yaml \
  --output metadata/output/data_contracts/output_sales_finance_pl.yaml
  
  yq -i --yaml-output \
    --arg version $(date '+%Y.%m.%d') \
    '
      .id |= "urn:datacontract:project:jaffle-shop:dbt:output-model:sales_finance_pl" |
      .info.title |= "Jaffle Shop OUTPUT Sales Finance P&L Data Contract" |
      .info.description |= "Data Contract for Example Jaffle Shop OUTPUT Sales Finance Profit/Loss Data provided by Mars/ created by dbt build." |
      .info.version |= $version
    ' \
    metadata/output/data_contracts/output_sales_finance_pl.yaml
fi

if [ "${1}" == "databricks" ]; then
  export DATABRICKS_CATALOG=$(cat dbt/logs/dbt_databricks_${DBT_ENV_TARGET}_config.log | grep -Po '(?<=catalog:\s)[a-zA-Z0-9_]+')
  export DATABRICKS_SCHEMA=$(cat dbt/logs/dbt_databricks_${DBT_ENV_TARGET}_config.log | grep -Po '(?<=schema:\s)[a-zA-Z0-9_]+')

  for contract in metadata/output/data_contracts/*.yaml; do
    if ! $( yq 'has("servers")' ${contract} ); then
      yq -i --yaml-output \
        --arg serverName "dna_databricks_${DBT_ENV_TARGET}" \
        --arg host ${DBT_ENV_SECRET_DATABRICKS_HOST:-NA} \
        --arg catalog ${DATABRICKS_CATALOG:-NA} \
        --arg schema ${DATABRICKS_SCHEMA:-NA} \
      '
        .servers |= {($serverName):
            {
              "type": "databricks",
              "host": $host,
              "catalog": $catalog,
              "schema": $schema
            }
          }
      ' ${contract}
    elif ! $( yq --arg serverName "dna_databricks_${DBT_ENV_TARGET}" '.servers | has($serverName)' ${contract} ); then
      yq -i --yaml-output \
        --arg serverName "dna_databricks_${DBT_ENV_TARGET}" \
        --arg host ${DBT_ENV_SECRET_DATABRICKS_HOST:-NA} \
        --arg catalog ${DATABRICKS_CATALOG:-NA} \
        --arg schema ${DATABRICKS_SCHEMA:-NA} \
      '
        .servers += {($serverName): 
            {
              "type": "databricks",
              "host": $host,
              "catalog": $catalog,
              "schema": $schema
            }
          }
      ' ${contract}
    fi
  done

elif [ "${1}" == "snowflake" ]; then

  export SNOWFLAKE_DATABASE=$(cat dbt/logs/dbt_snowflake_${DBT_ENV_TARGET}_config.log | grep -Po '(?<=database:\s)[a-zA-Z0-9_]+')
  export SNOWFLAKE_SCHEMA=$(cat dbt/logs/dbt_snowflake_${DBT_ENV_TARGET}_config.log | grep -Po '(?<=schema:\s)[a-zA-Z0-9_]+')

  for contract in metadata/output/data_contracts/*.yaml; do
    if ! $( yq 'has("servers")' ${contract} ); then
      yq -i --yaml-output \
        --arg serverName "dna_snowflake_${DBT_ENV_TARGET}" \
        --arg account ${DBT_ENV_SECRET_SNOWFLAKE_ACCOUNT:-NA} \
        --arg database ${SNOWFLAKE_DATABASE:-NA} \
        --arg schema ${SNOWFLAKE_SCHEMA:-NA} \
        '
          .servers |= {($serverName):
            {
              "type": "snowflake",
              "account": $account,
              "database": $database,
              "schema": $schema
            }
          }
      ' ${contract}
    elif ! $( yq --arg serverName "dna_snowflake_${DBT_ENV_TARGET}" '.servers | has($serverName)' ${contract} ); then
      yq -i --yaml-output \
        --arg serverName "dna_snowflake_${DBT_ENV_TARGET}" \
        --arg account ${DBT_ENV_SECRET_SNOWFLAKE_ACCOUNT:-NA} \
        --arg database ${SNOWFLAKE_DATABASE:-NA} \
        --arg schema ${SNOWFLAKE_SCHEMA:-NA} \
        '
          .servers += {($serverName):
            {
              "type": "snowflake",
              "account": $account,
              "database": $database,
              "schema": $schema
            }
          }
      ' ${contract}
    fi
  done
  
fi

deactivate