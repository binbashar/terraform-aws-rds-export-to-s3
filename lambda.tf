#
# This function triggers the start export task on rds if the event matches the
# database name and the event id for which this is configured.
#
module "start_export_task_lambda" {
  source = "github.com/terraform-aws-modules/terraform-aws-lambda?ref=v2.7.0"

  function_name = "${var.prefix}-rds-export-to-s3"
  description   = "RDS Export To S3"
  handler       = "index.handler"
  runtime       = "python3.8"
  publish       = true

  source_path = "${path.module}/functions/export-to-s3"

  environment_variables = {
    RDS_EVENT_ID: var.rds_event_id,
    DB_NAME: var.database_name,
    SNAPSHOT_BUCKET_NAME: var.snapshots_bucket_name,
    SNAPSHOT_TASK_ROLE: aws_iam_role.rdsSnapshotExportTask.arn,
    SNAPSHOT_TASK_KEY: aws_kms_key.snapshotExportEncryptionKey.arn,
    LOG_LEVEL: var.log_level,
  }

  attach_policy = true
  policy        = aws_iam_policy.rdsStartExportTaskLambda.arn

  tags = var.tags
}

#
# This function will react to rds snapshot export task events.
#
module "monitor_export_task_lambda" {
  source = "github.com/terraform-aws-modules/terraform-aws-lambda?ref=v2.7.0"

  function_name = "${var.prefix}-rds-export-to-s3-monitor"
  description   = "RDS Export To S3 Monitor"
  handler       = "index.handler"
  runtime       = "python3.8"
  publish       = true

  source_path = "${path.module}/functions/monitor-export-to-s3"

  environment_variables = {
    DB_NAME: var.database_name,
    SNS_NOTIFICATIONS_TOPIC_ARN: var.notifications_topic_arn,
    LOG_LEVEL: var.log_level,
  }

  tags = var.tags
}
