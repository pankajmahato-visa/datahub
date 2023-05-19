from datahub_open_api import DataHubOpenAPI
import datahub.emitter.mce_builder as builder

dataset_urn = builder.make_dataset_urn('mysql', 'bars.bar')
field_urn = builder.make_schema_field_urn(dataset_urn, 'c1')
api = DataHubOpenAPI()
print(api.get_dataset(dataset_urn=dataset_urn))

builder.make