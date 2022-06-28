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
    rdsEventID = os.environ["RDS_EVENT_ID"].replace(' ', '').split(',')
    dbName = os.environ['DB_NAME'].replace(' ', '').split(',')

    if eventId in rdsEventID:
        try:
          snapshotDbName=boto3.client("rds").describe_db_snapshots(DBSnapshotIdentifier=sourceId)['DBSnapshots'][0]['DBInstanceIdentifier']
        except: 
          snapshotDbName=boto3.client("rds").describe_db_cluster_snapshots(DBClusterSnapshotIdentifier=sourceId)['DBClusterSnapshots'][0]['DBClusterIdentifier']

        for db in dbName:
            if db == snapshotDbName:
                exportTaskId = (sourceId.replace("rds:","") + messageId)[:60]
                response = boto3.client("rds").start_export_task(
                    ExportTaskIdentifier=exportTaskId,
                    SourceArn=sourceArn,
                    S3BucketName=os.environ["SNAPSHOT_BUCKET_NAME"],
                    S3Prefix=os.environ["SNAPSHOT_BUCKET_PREFIX"],
                    IamRoleArn=os.environ["SNAPSHOT_TASK_ROLE"],
                    KmsKeyId=os.environ["SNAPSHOT_TASK_KEY"],
                )
                response["SnapshotTime"] = str(response["SnapshotTime"])

                logger.info(f"Snapshot export task started on {db}")
                logger.info(json.dumps(response))
            else:
                logger.info(f"Ignoring event notification for {sourceId} - {eventId}")
                logger.info(f"notifications for {dbName} only")

    else:
        logger.info(f"Ignoring event notification for {sourceId} - {eventId}")
        logger.info(f"Function is configured to accept {rdsEventID} only")

