from auto_tagging import AutoTagging
import datahub.emitter.mce_builder as builder
import json
import logging

if __name__ == '__main__':
     # create a logger instance
    logger = logging.getLogger(__name__)
    logger.setLevel(logging.DEBUG)

    # handler to send the logs to the console
    console_handler = logging.StreamHandler()
    console_handler.setLevel(logging.DEBUG)

    # formatter for the logs
    formatter = logging.Formatter(
        '%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    console_handler.setFormatter(formatter)

    # adding the console handler to the logger
    logger.addHandler(console_handler)

    auto_tagging = AutoTagging(logger=logger)
    dataset_urn = builder.make_dataset_urn('mysql', 'healthcare.treatment')
    snapshots, reports = auto_tagging.auto_tag(dataset_urn)
    if reports:
        print("~~~REPORT~~~\n", json.dumps(reports, indent=4))
    if snapshots:
        print(snapshots)
