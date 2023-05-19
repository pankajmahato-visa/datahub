from collections import deque
from datahub_open_api import DataHubOpenAPI
import datahub.emitter.mce_builder as builder
import logging
import json
from typing import List

class AutoTagging:
    def __init__(self, config_file='config.ini', logger = None):
        self.api = DataHubOpenAPI(config_file=config_file)
        self.reports = []
        self.snapshots = []
        self.logger = logger

    def get_untagged_fields_with_linages(self, dataset_urn):
        dataset = self.api.get_dataset(dataset_urn=dataset_urn)

        untagged_fields_with_lineage = [
            fields for fields in dataset['fields'].values()
            if not fields['tags'] and fields['upstreams']
        ]
        if self.logger:
            self.logger.debug(
                f"{len(untagged_fields_with_lineage)} untagged fields with lineages found.")

        return untagged_fields_with_lineage

    def add_to_report(self, source_field_urn: str, destination_field_urn: str, success: str = False, tags: List[str] = []):
        self.reports.append({
            'field_name': self.api.field_name_from_field_urn(
                destination_field_urn),
            'source_dataset': self.api.dataset_name_from_field_urn(
                source_field_urn),
            'source_field': self.api.field_name_from_field_urn(source_field_urn),
            'status': 'SUCCEDED' if success else 'NOT SUCCEDED',
            'tags': tags
        })

    def associate_tags_to_field(self, parent_field_urn: str, parent_tags: List[str], dataset_urn: str, field: dict) -> bool:
        """Associate a list of tags to a given field, needs parent information for reporting

        Args:
            parent_field_urn (str): Source field URN, needed for reporting
            parent_tags (List[str]): List of tags to add
            dataset_urn (str): the dataset to whose field the tags is to be added
            field (dict): the field that tags are to the added

        Returns:
            bool: True if successfully added, False if not
        """
        if self.logger:
            self.logger.debug(f"\tAdding parent tags to field...")
        tags_added = []
        # For each tag to be added
        for tag_urn in parent_tags:
            # Attempt adding tags and get a snapshot
            snapshot = self.api.add_tag_in_field(
                dataset_urn=dataset_urn,
                field_urn=field['field_urn'],
                tag_to_add=tag_urn,
                logger=self.logger
            )
            # Snapshot exists if successfully added
            if snapshot:
                # Save snapshot and remember the added tag
                self.snapshots.append(snapshot)
                tags_added.append(tag_urn)

        # If tags were added then report success else failure
        self.add_to_report(
            source_field_urn=parent_field_urn,
            destination_field_urn=field['field_urn'],
            success=True if tags_added else False,
            # If succes then what tags were added, else what tags weren't added
            tags=tags_added if tags_added else parent_tags
        )

        return True if tags_added else False

    def has_valid_ancestor_count(self, field, upstreams: List[str]) -> bool:
        # If there are more than one parent or no parent in lineage then skip
        if len(upstreams) > 1:
            if self.logger:
                self.logger.debug(
                    f"\tField {field['field_path']} has more than one parent in lineage. Skipping.")
            return False

        if len(upstreams) == 0:
            if self.logger:
                self.logger.debug(
                    f"\tField {field['field_path']} has no parent in lineage. Skipping"
                )
            return False

        return True

    def auto_tag(self, dataset_urn):
        if self.logger:
            self.logger.info(
                f"Performing auto-tagging for dataset: {dataset_urn}...")

        # Get Untagged fields
        untagged_fields_with_lineages = self.get_untagged_fields_with_linages(
            dataset_urn=dataset_urn
        )

        # For every untagged field
        for field in untagged_fields_with_lineages:
            if self.logger:
                self.logger.debug(
                    f"Performing auto-tag for field: {field['field_path']}...")

            # Mark this field as current field and start the search
            current_field = field
            search = True

            while search:
                # Get upstreams
                upstreams = current_field['upstreams']

                # Stop search if appropriate parent count not present
                if not self.has_valid_ancestor_count(field=field, upstreams=upstreams):
                    search = False
                    continue

                # Get single parent in lineage
                parent_field_urn = upstreams[0]
                if self.logger:
                    self.logger.debug(f"\tFound parent field {parent_field_urn}.")

                # Get parent dataset
                parent_dataset = self.api.get_dataset(
                    self.api.get_field_dataset_urn(
                        parent_field_urn)
                )

                # Get parent tags 
                parent_tags = parent_dataset['fields'][parent_field_urn]['tags']

                # If parent tags exists then associate tags with current field and stop search
                if parent_tags:
                    if self.logger:
                        self.logger.debug(f"\tTags found in parent {parent_field_urn}")
                    self.associate_tags_to_field(
                        parent_field_urn=parent_field_urn,
                        parent_tags=parent_tags,
                        dataset_urn=dataset_urn,
                        field=field
                    )
                    search = False
                # Else move one step up in the lineage
                else:
                    if self.logger:
                        self.logger.debug(
                            f"\tParent {parent_field_urn} doesn't have tags. Moving one step up in linage...")
                    # Mark parent as current field
                    current_field = parent_dataset['fields'][parent_field_urn]
                # Continue searching for a tagged parent

        # Save snapshot and report in result and clear current copies
        results = (self.snapshots.copy(), self.reports.copy())
        self.snapshots.clear()
        self.reports.clear()
        if self.logger:
            self.logger.debug(self.api.get_dataset.cache_info())
            self.logger.info("Auto-tagging completed.")
        return results
