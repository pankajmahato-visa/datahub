import logging
from typing import Iterable, Union
import pydantic

from datahub.configuration.common import ConfigModel
from datahub.ingestion.api.common import PipelineContext
from datahub.ingestion.api.source import Source, SourceReport
from datahub.ingestion.api.workunit import MetadataWorkUnit
from datahub.metadata.com.linkedin.pegasus2avro.mxe import MetadataChangeEvent
import datahub.emitter.mce_builder as builder
from datahub.ingestion.source.auto_tagging.core.auto_tagging import AutoTagging
from datahub.ingestion.source.auto_tagging.reporter import (
    index as auto_tagging_reporter,
)
from datahub.ingestion.source.auto_tagging.graphql_api import DataHubGraphqlAPI

logger = logging.getLogger(__name__)
console_handler = logging.StreamHandler()
logger.addHandler(console_handler)


# The class AutoTaggingSourceConfig has the configs for AutoTaggingSource
class AutoTaggingSourceConfig(ConfigModel):
    env: str = pydantic.Field(default="PROD", description="environment")
    search_level: Union[int, str] = pydantic.Field(
        default=3,
        description="Either an integer, in which case it is the search traverse level, or a string 'root', in which case it denotes to search traverse till the root",
    )
    include_data: list[dict] = pydantic.Field(description="include data")
    exclude_data: list = pydantic.Field(description="exclude data")
    include_view: list = pydantic.Field(description="include data")

    @pydantic.validator("include_data", always=True)
    def include_data_not_empty(cls, v, values, **kwargs):
        if (v == [] or v is None) and (values["include_view"] == [] or values["include_view"] is None):
            raise ValueError("include_data and include_view both are empty")
        return v


# The AutoTaggingSource class is a Python class that extends the Source class and provides methods for
# generating MetadataWorkUnits and reporting on the status of those work units.
class AutoTaggingSource(Source):
    source_config: AutoTaggingSourceConfig
    report: SourceReport = SourceReport()

    def __init__(
        self,
        config: AutoTaggingSourceConfig,
        ctx: PipelineContext,
        config_file="core/config.ini",
    ):
        super().__init__(ctx)
        self.source_config = config
        self.api = DataHubGraphqlAPI(config_file=config_file)

    @classmethod
    def create(cls, config_dict, ctx):
        config = AutoTaggingSourceConfig.parse_obj(config_dict)
        return cls(config, ctx)

    def get_workunits(self) -> Iterable[MetadataWorkUnit]:
        """
        This function creates a MetadataChangeEvent object from it, creates a
        MetadataWorkUnit object from the MCE, reports the work unit, and yields the work unit.
        """
        for view_urn in self.source_config.include_view:
            include_view_dataset = self.api.get_datasets_from_datahub_view(view_urn)
            if include_view_dataset:
                yield from self.auto_tagger(
                    include_view_dataset, self.source_config.exclude_data
                )
        yield from self.auto_tagger(
            self.source_config.include_data, self.source_config.exclude_data
        )

    def auto_tagger(self, include_data, exclude_data) -> Iterable[MetadataWorkUnit]:
        """
        This function performs auto-tagging on datasets and generates metadata work units for the
        snapshots.

        :param include_data: The include_data parameter is a list of dictionaries containing information
        about the datasets to be included in the auto-tagging process. Each dictionary represents a
        dataset and includes the platform, schema (if applicable), and table name
        :param exclude_data: The `exclude_data` parameter is a list of dictionaries containing
        information about datasets that should be excluded from the auto-tagging process. The function
        uses this information to check if a dataset should be excluded before attempting to auto-tag it
        """
        exclude_dataset_urns = self.get_exclude_dataset_urns(exclude_data)
        for conf in include_data:
            auto_tagging = AutoTagging()
            if "schema" not in conf:
                dataset_name = conf["table"]
            else:
                dataset_name = f"{conf['schema']}.{conf['table']}"

            dataset_urn = builder.make_dataset_urn(
                platform=conf["platform"], name=dataset_name
            )
            if dataset_urn not in exclude_dataset_urns:
                at = auto_tagging.auto_tag(dataset_urn)
                snapshots = at["snapshots"]
                auto_tag_reports = at["reports"]
                if auto_tag_reports:
                    logger.debug("Auto-tagging completed. Sending Email...")
                    atr = auto_tagging_reporter(auto_tag_reports)
                    atr.send_report()
                if snapshots:
                    for dataset_snapshot in snapshots:
                        logger.debug(f"Snapshot: {dataset_snapshot}")
                        mce = MetadataChangeEvent(proposedSnapshot=dataset_snapshot)
                        wu = MetadataWorkUnit("auto_tagging", mce=mce)
                        self.report.report_workunit(wu)
                        yield wu
                else:
                    logger.debug("No Snapshots")
            else:
                print(f"Excluded: {conf}")
                logger.debug(f"Excluded: {conf}")

    def get_exclude_dataset_urns(self, exclude_data):
        """
        This function builds a list of dataset URNs to exclude based on input data.

        :param exclude_data: The `exclude_data` parameter is a list of dictionaries containing
        information about datasets that should be excluded from a certain operation. Each dictionary in
        the list contains the following keys: "platform" (string), "schema" (string, optional), and
        "table" (string).
        :return: a list of dataset URNs that are built from the input `exclude_data`.
        The `exclude_data` is a list of dictionaries that contain information about the
        datasets to be excluded. The function loops through each dictionary in `exclude_data`, extracts
        the dataset name and platform information, and uses them to build a dataset URN using the
        `builder.make_dataset_urn() function.
        """
        # Build exclude_data dataset urns
        exclude_dataset_urns = []
        for e_data in exclude_data:
            if "schema" not in e_data:
                dataset_name = e_data["table"]
            else:
                dataset_name = f"{e_data['schema']}.{e_data['table']}"
            exclude_dataset_urns.append(
                builder.make_dataset_urn(platform=e_data["platform"], name=dataset_name)
            )
        return exclude_dataset_urns

    def get_report(self) -> SourceReport:
        return self.report

    def close(self) -> None:
        pass
