#
# This function triggers the start export task on rds if the event matches the
# database name and the event id for which this is configured.
#
module "start_export_task_lambda" {
  source = "github.com/terraform-aws-modules/terraform-aws-lambda?ref=v6.4.0"

  function_name = "${local.prefix}rds-export-to-s3${local.postfix}"
  description   = "RDS Export To S3"
  handler       = "index.handler"
  runtime       = "python3.8"
  publish       = true

  cloudwatch_logs_retention_in_days = 90

  source_path = "${path.module}/functions/export-to-s3"

  environment_variables = {
    RDS_EVENT_ID : var.rds_event_ids,
    DB_NAME : var.database_names,
    SNAPSHOT_BUCKET_NAME : var.snapshots_bucket_name,
    SNAPSHOT_BUCKET_PREFIX : var.snapshots_bucket_prefix,
    SNAPSHOT_TASK_ROLE : aws_iam_role.rdsSnapshotExportTask.arn,
    SNAPSHOT_TASK_KEY : var.create_customer_kms_key ? aws_kms_key.snapshotExportEncryptionKey[0].arn : var.customer_kms_key_arn
    LOG_LEVEL : var.log_level,
  }

  attach_policy = true
  policy        = aws_iam_policy.rdsStartExportTaskLambda.arn

  tags = merge({ Name = "${local.prefix}rds-export-to-s3${local.postfix}" }, var.tags)
}

#
# This function will react to rds snapshot export task events.
#
module "monitor_export_task_lambda" {
  source = "github.com/terraform-aws-modules/terraform-aws-lambda?ref=v2.23.0"

  function_name = "${local.prefix}rds-export-to-s3-monitor${local.postfix}"
  description   = "RDS Export To S3 Monitor"
  handler       = "index.handler"
  runtime       = "python3.8"
  publish       = true

  cloudwatch_logs_retention_in_days = 90

  source_path = "${path.module}/functions/monitor-export-to-s3"

  environment_variables = {
    DB_NAME : var.database_names,
    SNS_NOTIFICATIONS_TOPIC_ARN : var.create_notifications_topic ? aws_sns_topic.exportMonitorNotifications[0].arn : var.notifications_topic_arn,
    LOG_LEVEL : var.log_level,
  }

  attach_policy = true
  policy        = aws_iam_policy.rdsMonitorExportTaskLambda.arn

  tags = merge({ Name = "${local.prefix}rds-export-to-s3-monitor${local.postfix}" }, var.tags)
}
