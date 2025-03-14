# Introduction 
The Data Control Plane experiment is an innovative approach to data transformation and governance, building upon the foundations of dbt (data build tool) Seed. This project aims to transition from a traditional data warehousing approach to a modern, ELT (Extract, Load, Transform) based transformation framework, leveraging dbt's powerful SQL language and semantic modeling capabilities.

dbt Seed provides a robust foundation for data transformation, but it has limitations when it comes to scalability, flexibility, and governance. The Data Control Plane experiment addresses these limitations by introducing a new paradigm for data transformation, one that emphasizes data contracts, semantic modeling, and ELT transformations.

Key Components

Data Contracts: Establishing clear, well-defined data contracts between data producers and consumers, ensuring that data is consistent, accurate, and reliable.
Semantic Modeling: Utilizing dbt's semantic modeling capabilities to define a common language for data, enabling better data understanding, and facilitating data reuse.
ELT Transformations: Leveraging dbt's SQL language to perform ELT transformations, allowing for faster, more efficient data processing, and reducing the need for manual data manipulation.
dbt Source and Staging: Building upon dbt's source and staging capabilities to establish a robust data foundation, accelerating builds, and improving data quality.

Data Contract Manager can be visited [Here](https://datacontractmanagerpoc.azurewebsites.net/mars).

# Getting Started
If you haven't started the dbt-seed project, navigate [Here](https://github.com/effem-jg-org/dbt-seed-example). To see all the tasks in this project, run this command: `task --list-all`.

# Build and Test

## Sources, Stage Tables and Transformations

We will leverage the Data Contracts created in the dbt-seed project to seamlessly export Source or Stage view materializations and dbt Contracts, ensuring a unified schema across projects. The datacontract CLI empowers us to generate schema contracts from our dbt models, which can then be used to enforce data consistency throughout our data pipeline. This approach enables us to decouple our data sources from our data transformations, streamlining the management of complex data pipelines and guaranteeing data quality. By defining the schema of our data sources using Data Contracts, we can ensure that our data remains consistent and accurate, regardless of the project or data source. This facilitates the creation of robust and scalable data pipelines, making it easier to integrate new data sources or projects into our existing data architecture.

```bash
# Run the following task to download the dbt-seed Data Contracts into our project's metadata/input folders, and leverage datacontract-cli to manifest dbt foundational lineage.
task dcm:build_dbt_sources
```

We're also leveraging the great upfront transformational work done originally by dbt, in the Jaffle-Shop repo [Here](https://github.com/dbt-labs/jaffle-shop/tree/main/models/marts). These transformations are already avaiable in this repo, so we can go ahead and send the build steps to our Data Warehouses.

```bash
# Run the Databricks build steps 
task dbt:build_databricks

# Run the Snowflake build steps
task dbt:build_snowflake
```

## Data Governance Layer

By leveraging the Data Contracts from a previous project, we were able to create a robust foundation for our current data pipeline. These Data Contracts not only established a clear lineage between projects, but also enabled us to automatically deploy foundational dbt build steps, streamlining our development process and reducing errors. Furthermore, we were able to extend the transformation into new Data Contracts, allowing us to propagate data consistency and quality across our organization. This approach also enabled us to extend governance across our data pipeline, ensuring that data is accurate, complete, and compliant with regulatory requirements. By building on the foundation of our previous project's Data Contracts, we were able to create a scalable and maintainable data architecture that supports our organization's growing data needs. The use of Data Contracts has been instrumental in enabling us to achieve a high level of data quality, consistency, and governance, and has set us up for success as we continue to evolve and expand our data capabilities.

```bash

# Import new Data Contracts from the dbt transformations and publish into Data Contract Manager. This task also created Usage Agreements between the dbt-seed data products and our dbt-transformation products.
task dcm:publish_databricks

# Run the same to consolidate the details with our Snwoflake deployment
task dcm:publish_snowflake

```


## Data quality

*Under Construction*


# Tear Down

```bash

task dcm:clean
task dbt:clean

```