"""
Placeholder Lambda handler. Polls messages off the SQS buffer queue
(see terraform/modules/notification-pipeline) instead of being invoked
directly by S3, so that disabling the SQS->Lambda event source mapping
during a repave doesn't drop any events — they just wait in the queue.

TODO: replace with your real processing logic.
"""
import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    records = event.get("Records", [])
    logger.info("Received %d SQS message(s)", len(records))

    for record in records:
        body = record.get("body", "{}")
        try:
            payload = json.loads(body)
        except json.JSONDecodeError:
            logger.warning("Non-JSON message body, skipping: %s", body)
            continue

        # TODO: real handling of the S3/EventBridge notification payload goes here.
        logger.info("Processing payload: %s", payload)

    return {"statusCode": 200, "processed": len(records)}
