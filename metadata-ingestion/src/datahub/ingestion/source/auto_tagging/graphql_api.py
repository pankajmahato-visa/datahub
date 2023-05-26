import configparser

# read-modify-write requires access to the DataHubGraph (RestEmitter is not enough)
from datahub.ingestion.graph.client import DatahubClientConfig, DataHubGraph


class DataHubGraphqlAPI:
    def __init__(self, config_file="config.ini"):
        self.config = configparser.ConfigParser()
        try:
            self.config.read(config_file)
            self.gms_endpoint = self.config.get("API", "gms_endpoint")
            self.api_retry_count = int(self.config.get("API", "api_retry_count"))
            self.api_timeout_sec = int(self.config.get("graphql", "api_timeout_sec"))
            self.api_retry_status_codes = list(
                int(code) for code in self.config.get("graphql", "api_timeout_sec").split(",")
            )
            self.get_dataset_urns_from_view = self.config.get(
                "graphql", "get_dataset_urns_from_view"
            )
        except Exception as e:
            print(f"An error occured: {e}")
            raise e

    def get_datasets_from_datahub_view(self, urn):
        """
        This function retrieves datasets from a datahub view using a GraphQL query and returns a list of
        dictionaries containing the platform and table name for each dataset.
        
        :param urn: The `urn` parameter is a string representing the unique identifier of a datahub
        view. The function uses this parameter to retrieve a list of datasets that are included in the
        view
        :return: a list of dictionaries, where each dictionary contains the name of a dataset and the
        platform it belongs to. The datasets are obtained from a datahub view specified by the input
        parameter `urn`.
        """
        graph = DataHubGraph(
            DatahubClientConfig(
                server=self.gms_endpoint,
                timeout_sec=self.api_timeout_sec,
                retry_status_codes=self.api_retry_status_codes,
                retry_max_times=self.api_retry_count,
            )
        )
        variables = {
            "input": {
                "types": ["DATASET"],
                "query": "",
                "viewUrn": urn,
            }
        }
        result = graph.execute_graphql(
            query=self.get_dataset_urns_from_view, variables=variables
        )

        include_dataset = []
        searchResults = result["searchAcrossEntities"]["searchResults"]
        for entity in searchResults:
            table = entity["entity"]["name"]
            data_platform = entity["entity"]["platform"]["name"]
            include_dataset.append({"platform": data_platform, "table": table})
        return include_dataset
