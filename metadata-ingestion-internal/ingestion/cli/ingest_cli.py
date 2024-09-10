# Code change 1
import traceback

    async def run_pipeline_to_completion(pipeline: Pipeline) -> int:
        logger.info("Starting metadata ingestion")
        with click_spinner.spinner(disable=no_spinner or no_progress):
            try:
                pipeline.run()
            except Exception as e:
                logger.info(
                    f"Source ({pipeline.source_type}) report:\n{pipeline.source.get_report().as_string()}"
                )
                logger.info(
                    f"Sink ({pipeline.sink_type}) report:\n{pipeline.sink.get_report().as_string()}"
                )
                #raise e
                logger.info(
                    f"{e} ... skipping ahead. {''.join(traceback.format_tb(e.__traceback__))}"
                )
            else:
                logger.info("Finished metadata ingestion")
                pipeline.log_ingestion_stats()
                ret = pipeline.pretty_print_summary(warnings_as_failure=strict_warnings)
                return ret




# Code change 2
    async def run_ingestion_and_check_upgrade() -> int:
        # TRICKY: We want to make sure that the Pipeline.create() call happens on the
        # same thread as the rest of the ingestion. As such, we must initialize the
        # pipeline inside the async function so that it happens on the same event
        # loop, and hence the same thread.

        # logger.debug(f"Using config: {pipeline_config}")
        pipeline = Pipeline.create(
            pipeline_config,
            dry_run,
            preview,
            preview_workunits,
            report_to,
            no_default_report,
            no_progress,
            raw_pipeline_config,
        )

        version_stats_future = asyncio.ensure_future(
            upgrade.retrieve_version_stats(pipeline.ctx.graph)
        )
        ingestion_future = asyncio.ensure_future(run_pipeline_to_completion(pipeline))
        ret = await ingestion_future

        # The main ingestion has completed. If it was successful, potentially show an upgrade nudge message.
        if ret == 0:
            try:
                # we check the other futures quickly on success
                version_stats = await asyncio.wait_for(version_stats_future, 0.5)
                upgrade.maybe_print_upgrade_message(version_stats=version_stats)
            except Exception as e:
                logger.debug(
                    f"timed out with {e} waiting for version stats to be computed... skipping ahead."
                )

        return ret

    loop = asyncio.get_event_loop()
    ret = loop.run_until_complete(run_ingestion_and_check_upgrade())
#     if ret:
#         sys.exit(ret)
    # don't raise SystemExit if there's no error
