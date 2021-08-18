import json
import logging
import os
import re
import boto3

"""
This function listens for RDS events that indicate that an automated snapshot
has been created in order to start an RDS snapshot export to S3.
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
    messageId = event["Records"][0]["Sns"]["MessageId"]
    eventId = message["detail"]["EventID"]
    sourceId = message["detail"]["SourceIdentifier"]
    sourceArn = message["detail"]["SourceArn"]
    matchSnapshotRegEx = "^rds:" + os.environ["DB_NAME"] + "-\d{4}-\d{2}-\d{2}-\d{2}-\d{2}$"

    if eventId.endswith(os.environ["RDS_EVENT_ID"]) and re.match(matchSnapshotRegEx, sourceId):
        exportTaskId = ((sourceId[4:] + '-').replace("--", "-") + messageId)[:60]
        response = boto3.client("rds").start_export_task(
            ExportTaskIdentifier=exportTaskId,
            SourceArn=sourceArn,
            S3BucketName=os.environ["SNAPSHOT_BUCKET_NAME"],
            IamRoleArn=os.environ["SNAPSHOT_TASK_ROLE"],
            KmsKeyId=os.environ["SNAPSHOT_TASK_KEY"],
        )
        response["SnapshotTime"] = str(response["SnapshotTime"])

        logger.info("Snapshot export task started")
        logger.info(json.dumps(response))

    else:
        logger.info(f"Ignoring event notification for {sourceId}")
        logger.info(
            f"Function is configured to accept {os.environ['RDS_EVENT_ID']} "
            f"notifications for {os.environ['DB_NAME']} only"
        )
