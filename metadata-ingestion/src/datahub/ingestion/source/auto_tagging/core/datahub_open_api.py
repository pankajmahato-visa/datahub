from typing import List, Dict, Optional, Any
import json
import requests
import configparser
import datahub.emitter.mce_builder as builder
import time
import re
# read-modify-write requires access to the DataHubGraph (RestEmitter is not enough)
from datahub.ingestion.graph.client import DatahubClientConfig, DataHubGraph
from datahub.metadata.com.linkedin.pegasus2avro.metadata.snapshot import DatasetSnapshot
# Imports for metadata model classes
from datahub.emitter.mcp import MetadataChangeProposalWrapper
from datahub.metadata.schema_classes import (
    AuditStampClass,
    EditableSchemaFieldInfoClass,
    EditableSchemaMetadataClass,
    GlobalTagsClass,
    TagAssociationClass,
)
from jsonpath_ng import parse
from functools import lru_cache
from retry import retry


class DataHubOpenAPI:
    def __init__(self, config_file='config.ini'):
        self.config = configparser.ConfigParser()
        self.config.read(config_file)
        self.max_cache_size = int(self.config.get("API", "max_cache_size"))
        self.api_retry_delay = int(self.config.get("API", "api_retry_delay"))
        self.api_retry_count = int(self.config.get("API", "api_retry_count"))
        self.endpoint = self.config.get('API', 'entities_endpoint')
        self.user = self.config.get("auto_tagging", "user")

        # Add LRU functionality with max cache size from config
        self.get_dataset = lru_cache(
            maxsize=self.max_cache_size)(self.get_dataset)
        # Add retry capability to API calling function with retry proprties from config 
        self._get_data_from_api = retry(
            requests.RequestException,
            delay=self.api_retry_delay,
            tries=self.api_retry_count)(self._get_data_from_api)

    def _get_data_from_api(self, entitiy_urn, aspect_list):
        """
        Retrieves data from the API based on a dataset URN and a list of aspects.

        Args:
            dataset_urn (str): URN of the dataset to retrieve data from.
            aspect_list (list): List of aspect names to retrieve data for.

        Returns:
            dict: A dictionary containing the retrieved data.
        """
        query = {
            'urns': [entitiy_urn],
            'aspectNames': aspect_list
        }
        try:
            response = requests.get(self.endpoint, query)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            print(f"An error occured: {e}")
            raise e

    def _find_in_json(self, expression, data):
        """
        Helper method to search for JSON path expression in response data

        Args:
            expression (str): JSON path expression to search for
            data (dict): Response data from API

        Returns:
            List: List of matches for the given JSON path expression in the response data
        """
        parsed_expression = parse(expression)
        match = [
            match.value for match in parsed_expression.find(data)]
        return match

    def get_field_dataset_urn(self, field_urn):
        """
        Retrieve the URN of the parent(dataset containing te field) of a given field URN.

        Args:
            field_urn (str): The URN of the field to retrieve the parent URN for.

        Returns:
            str or None: The URN of the parent of the given field URN, or None if no parent URN is found.
        """
        # Get the JSON data for the field_urn
        field_json = self._get_data_from_api(field_urn, [])

        # Get the URN of the field's parent
        parent_in_field_entity_json_path = self.config.get(
            'json_path_expression',
            'parent_in_field_entity'
        ).format(dataset_urn=field_urn)
        parent_urn_match = self._find_in_json(
            parent_in_field_entity_json_path, field_json)

        if parent_urn_match:
            return parent_urn_match[0]

        return None

    def field_name_from_field_urn(self, field_urn, dataset_urn=None):
        if not dataset_urn:
            field_name_pattern = r".(\w+)\)$"

            match = re.search(field_name_pattern, field_urn)
            if match:
                field_name = match.group(1)
                return field_name
            return ""

        field_name_pattern = re.compile(rf"{re.escape(dataset_urn)},(\w+)")

        match = field_name_pattern.search(field_urn)

        if match:
            field_name = match.group(1)
            return field_name
        return ""

    def dataset_name_from_field_urn(self, field_urn):
        dataset_name_pattern = r"urn:li:dataset:\(urn:li:dataPlatform:(.*?),([^,]+),([^)]+)\)"

        match = re.search(dataset_name_pattern, field_urn)
        if match:
            dataset_name = match.group(2)
            return dataset_name
        else:
            return ""

    def get_simple_field_path_from_v2_field_path(self, field_path: str) -> str:
        """A helper function to extract simple . path notation from the v2 field path"""
        if not field_path.startswith("[version=2.0]"):
            # not a v2, we assume this is a simple path
            return field_path
            # this is a v2 field path
        tokens = [
            t for t in field_path.split(".") if not (t.startswith("[") or t.endswith("]"))
        ]

        return ".".join(tokens)

    def extract_fields_from_schema_metadata(self, dataset_data, dataset_urn: str) -> Dict[str, Any]:
        """For a given json response for schema metadata, get all the fields in that dataset

        Args:
            dataset_data (dict): json response from server for schema metadata
            dataset_urn (str): URN of the dataset

        Returns:
            Dict[str, Any]: fields[field_urn] = {'field_path': field_name, 'field_urn': field_urn, 'tags': [], 'upstreams': []}
        """
        schema_metadata_fields_json_path = self.config.get(
            'json_path_expression',
            'schema_metadata_fields'
        ).format(dataset_urn=dataset_urn)
        schema_metadata_fields_match = self._find_in_json(
            expression=schema_metadata_fields_json_path, data=dataset_data)

        schema_metadata_fields = []
        if schema_metadata_fields_match:
            schema_metadata_fields = schema_metadata_fields_match[0]

        fields = {}

        for field in schema_metadata_fields:
            field_name = field['fieldPath']
            field_urn = builder.make_schema_field_urn(
                dataset_urn, field_name)
            fields[field_urn] = {
                'field_path': field_name,
                'field_urn': field_urn,
                'tags': [],
                'upstreams': []
            }

        return fields

    def populate_tags_in_dataset_fields_dict(self, dataset_data, dataset_urn: str, fields: Dict[str, Any]) -> None:
        # This has field names and tags
        tagged_fields_json_path = self.config.get(
            'json_path_expression',
            'tagged_fields_in_editable_schema_metadata'
        ).format(dataset_urn=dataset_urn)
        tagged_fields = self._find_in_json(
            expression=tagged_fields_json_path, data=dataset_data)

        tags_in_field_path = self.config.get(
            'json_path_expression',
            'tags_in_field'
        )

        for field in tagged_fields:
            tags = self._find_in_json(
                expression=tags_in_field_path, data=field)
            field_name = field['fieldPath']
            if field_name and tags:
                field_urn = builder.make_schema_field_urn(
                    dataset_urn, field_name)
                fields[field_urn]['tags'].extend(tags)

    def populate_lineage_in_dataset_fields_dict(self, dataset_data, dataset_urn: str, fields: Dict[str, Any]) -> None:
        # This gives all upstream lineages
        upstream_lineage_json_path = self.config.get(
            'json_path_expression',
            'dataset_upstream_lineage'
        ).format(dataset_urn=dataset_urn)
        upstream_lineages = self._find_in_json(
            expression=upstream_lineage_json_path, data=dataset_data
        )

        for lineage in [lineage for lineage in upstream_lineages if lineage['upstreamType'] == 'FIELD_SET']:
            if 'downstreams' in lineage:
                for downstream in lineage['downstreams']:
                    fields[downstream]['upstreams'].extend(
                        lineage['upstreams'])

    def get_dataset(self, dataset_urn: str) -> List[Dict[str, Any]]:
        """Get dataset data containing fields along with associated tags as a dict. The keys 
        are the field_urns and the value is a dict that gives field name in `field_path`
        and a list of tag urns in `tags`

        Args:
            dataset_urn (str): The dataset_urn whose fields are to be retrieved.

        Returns:
            List[Dict[str, Any]]: {"field_urn": {field_path: "field name", tags["list", "of", "tag", "urns"]}}
        """
        # Else get data from API
        dataset_data = self._get_data_from_api(dataset_urn,
                                               ['schemaMetadata', 'editableSchemaMetadata', 'upstreamLineage'])

        # Get all fields
        fields = self.extract_fields_from_schema_metadata(
            dataset_data=dataset_data, dataset_urn=dataset_urn)

        # Get all tags
        self.populate_tags_in_dataset_fields_dict(
            dataset_data=dataset_data, dataset_urn=dataset_urn, fields=fields)

        # Get all lineage information
        self.populate_lineage_in_dataset_fields_dict(
            dataset_data=dataset_data, dataset_urn=dataset_urn, fields=fields)

        dataset = {}
        dataset['fields'] = fields

        return dataset

    def add_tag_in_field(self, dataset_urn, field_urn, tag_to_add, logger=None):
        """Add tags to given dataset field

        Args:
            dataset_urn (str): URN of Dataset that has the field to which tags are to be added
            field_urn (str): URN of field to which tags are to be added
            tag_to_add (str): URN of tag to be added

        Returns:
            _type_: _description_
        """
        column = self.field_name_from_field_urn(field_urn, dataset_urn)

        # First we get the current editable schema metadata
        gms_endpoint = self.config.get('API', 'gms_endpoint')
        graph = DataHubGraph(DatahubClientConfig(server=gms_endpoint, token=None,
                                                 timeout_sec=None,
                                                 retry_status_codes=None,
                                                 retry_max_times=None,
                                                 extra_headers=None,
                                                 ca_certificate_path=None))

        current_editable_schema_metadata = graph.get_aspect(
            entity_urn=dataset_urn,
            aspect_type=EditableSchemaMetadataClass,
        )

        # Some pre-built objects to help all the conditional pathways
        tag_association_to_add = TagAssociationClass(tag=tag_to_add)
        tags_aspect_to_set = GlobalTagsClass(tags=[tag_association_to_add])
        field_info_to_set = EditableSchemaFieldInfoClass(
            fieldPath=column, globalTags=tags_aspect_to_set
        )

        need_write = False
        field_match = False
        if current_editable_schema_metadata:
            for fieldInfo in current_editable_schema_metadata.editableSchemaFieldInfo:
                if self.get_simple_field_path_from_v2_field_path(fieldInfo.fieldPath) == column:
                    # we have some editable schema metadata for this field
                    field_match = True
                    if fieldInfo.globalTags:
                        if tag_to_add not in [x.tag for x in fieldInfo.globalTags.tags]:
                            # this tag is not present
                            fieldInfo.globalTags.tags.append(
                                tag_association_to_add)
                            need_write = True
                    else:
                        fieldInfo.globalTags = tags_aspect_to_set
                        need_write = True

            if not field_match:
                # this field isn't present in the editable schema metadata aspect, add it
                field_info = field_info_to_set
                current_editable_schema_metadata.editableSchemaFieldInfo.append(
                    field_info)
                need_write = True

        else:
            # create a brand new editable schema metadata aspect
            now = int(time.time() * 1000)  # milliseconds since epoch
            current_timestamp = AuditStampClass(
                time=now, actor=self.user)
            current_editable_schema_metadata = EditableSchemaMetadataClass(
                editableSchemaFieldInfo=[field_info_to_set],
                created=current_timestamp,
            )
            need_write = True

        if need_write:
            event: MetadataChangeProposalWrapper = MetadataChangeProposalWrapper(
                entityUrn=dataset_urn,
                aspect=current_editable_schema_metadata,
            )
            snapshot: DatasetSnapshot = DatasetSnapshot(
                urn=dataset_urn,
                aspects=[current_editable_schema_metadata]
            )
            graph.emit(event)
            if logger:
                logger.info(
                    f"Tag {tag_to_add} added to column {column} of dataset {dataset_urn}")
            return snapshot

        elif logger:
            logger.info(
                f"Tag {tag_to_add} already attached to column {column}, omitting write")
