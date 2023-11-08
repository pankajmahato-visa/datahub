import json
import logging
from typing import Optional

from pydantic import BaseModel

from datahub_actions.action.action import Action
from datahub_actions.event.event_envelope import EventEnvelope
from datahub_actions.pipeline.pipeline_context import PipelineContext

import datahub.emitter.mce_builder as builder
from datahub.emitter.mcp import MetadataChangeProposalWrapper
from datahub.metadata.schema_classes import RoleMembershipClass, ChangeTypeClass

from datahub.emitter.rest_emitter import DatahubRestEmitter

logger = logging.getLogger(__name__)

# Set PYTHONPATH for executing action without pip install -e .
# export PYTHONPATH=/actions-src/dh_default_role

class DefaultRoleConfig(BaseModel):
    # Whether to print the message in upper case.
    gms_host: Optional[str]
    gms_port: Optional[int]
    gms_token: Optional[str]
    gms_scheme: Optional[str]
    role: Optional[str]


# A basic example of a DataHub action that prints all
# events received to the console.
class DefaultRoleAction(Action):

    emitter = None

    @classmethod
    def create(cls, config_dict: dict, ctx: PipelineContext) -> "Action":
        action_config = DefaultRoleConfig.parse_obj(config_dict or {})
        return cls(action_config, ctx)

    def __init__(self, config: DefaultRoleConfig, ctx: PipelineContext):
        logger.info("Initializing datahub action RoleMembershipAction.")
        self.config = config
        if self.config.role is None:
            self.config.role = "urn:li:dataHubRole:Reader"
        
        self.emitter = DatahubRestEmitter(
            gms_server=f"{config.gms_scheme}://{config.gms_host}:{config.gms_port}", 
            extra_headers={},
            token=config.gms_token
        )
        self.emitter.test_connection()

    def act(self, event: EventEnvelope) -> None:
        # message = json.dumps(json.loads(event.as_json()), indent=4)
        # print(message)
        logger.info(f"RoleMembershipAction - Updating urn: {str(event.event.entityUrn)} with role: {self.config.role}")

        mcp = MetadataChangeProposalWrapper(
            entityUrn=event.event.entityUrn,
            aspect=RoleMembershipClass(
                roles=[self.config.role]
            ),
            changeType=ChangeTypeClass.UPSERT,
        )
        logger.debug("RoleMembershipAction: MCP being emitted, " + str(mcp))

        self.emitter.emit(mcp)
        logger.info("Successfully emitted role aspect.")

    def close(self) -> None:
        logger.info("Closing datahub action RoleMembershipAction.")
