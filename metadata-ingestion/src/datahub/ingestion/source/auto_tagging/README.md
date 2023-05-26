## Script for custom ingestion in DataHub

- pip install the package "auto_tagging" in your DataHub env using the command `pip install -e .`
- then use the recipe "auto_tagging_recipe.yaml" to configure the script.
- command to ingest the data `datahub --debug ingest -c auto_tagging_recipe.yaml`.
- The output will be stored in the DataHub UI's Ingestion Page.
