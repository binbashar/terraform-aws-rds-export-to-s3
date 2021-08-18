import json
import logging
import os
import re
import boto3

"""
This function captures RDS snapshot export task events in order to create a
summarized message out of it that it then publishes to a given SNS topic.
"""

logger = logging.getLogger()
logger.setLevel(os.getenv("LOG_LEVEL", logging.INFO))

def handler(event, context):
    if event["Records"][0]["EventSource"] != "aws:sns":
        logger.warning(
            "This function only supports invocations via SNS events, "
            "but was triggered by the following:\n"
            f"{json.dumps(event)}"
        )
        return

    logger.debug("EVENT INFO:")
    logger.debug(json.dumps(event))

    message = json.loads(event["Records"][0]["Sns"]["Message"])
    eventId = message["detail"]["EventID"]
    sourceType = message["detail"]["SourceType"]
    sourceId = message["detail"]["SourceIdentifier"]
    sourceArn = message["detail"]["SourceArn"]

    # Ref: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_Events.Messages.html#USER_Events.Messages.snapshot
    # Ref: https://docs.amazonaws.cn/en_us/AmazonRDS/latest/AuroraUserGuide/USER_Events.Messages.html#USER_Events.Messages.cluster-snapshot
    supportedEvents = {
        # RDS (non-Aurora)
        "RDS-EVENT-0159": "DB snapshot export task failed",
        "RDS-EVENT-0160": "DB snapshot export task canceled",
        "RDS-EVENT-0161": "DB snapshot export task completed",
        # RDS Aurora
        "RDS-EVENT-0162": "DB cluster snapshot export task failed",
        "RDS-EVENT-0163": "DB cluster snapshot export task canceled",
        "RDS-EVENT-0164": "DB cluster snapshot export task completed"
    }
    matchSnapshotRegEx = "^rds:" + os.environ["DB_NAME"] + "-\d{4}-\d{2}-\d{2}-\d{2}-\d{2}$"

    if eventId in supportedEvents.keys() and re.match(matchSnapshotRegEx, sourceId):
        messageTitle = supportedEvents[eventId]
        messageBody = {
            "SourceType": sourceType,
            "SourceIdentifier": sourceId,
            "SourceArn": sourceArn
        }
        response = boto3.client('sns').publish(
            TargetArn=os.environ["SNS_NOTIFICATIONS_TOPIC_ARN"],
            Subject=messageTitle,
            Message=json.dumps({'default': json.dumps(messageBody)}),
            MessageStructure='json'
        )

    else:
        logger.info(f"Ignoring event notification for {sourceId}")
        logger.info(
            f"Function is configured to accept {supportedEvents} "
            f"notifications for {os.environ['DB_NAME']} only"
        )
