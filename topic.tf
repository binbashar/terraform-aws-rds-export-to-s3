#
# Create an SNS Topic for receiving RDS Snapshot Events
#
resource "aws_sns_topic" "rdsSnapshotsEvents" {
  name = "${local.prefix}rds-snapshots-creation"
  tags = merge({ Name = "${local.prefix}rds-snapshots-creation" }, var.tags)
}


resource "aws_sns_topic" "exportMonitorNotifications" {
  count = var.create_notifications_topic ? 1 : 0
  name  = "${local.prefix}rds-exports-monitor-notifications"
  tags  = merge({ Name = "${local.prefix}rds-exports-monitor-notifications" }, var.tags)
}

#
# Allow CloudWatch to publish events on the SNS Topics
#
resource "aws_sns_topic_policy" "default" {
  arn    = aws_sns_topic.rdsSnapshotsEvents.arn
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "events.amazonaws.com"
            },
            "Action": "SNS:Publish",
            "Resource": "${aws_sns_topic.rdsSnapshotsEvents.arn}"
        }
    ]
}
POLICY
}

#
# Subscribe Lambdas to the Topics
#
resource "aws_sns_topic_subscription" "lambdaRdsSnapshotToS3Exporter" {
  topic_arn = aws_sns_topic.rdsSnapshotsEvents.arn
  protocol  = "lambda"
  endpoint  = module.start_export_task_lambda.lambda_function_arn
}

resource "aws_sns_topic_subscription" "lambdaRdsSnapshotToS3Monitor" {
  topic_arn = aws_sns_topic.rdsSnapshotsEvents.arn
  protocol  = "lambda"
  endpoint  = module.monitor_export_task_lambda.lambda_function_arn
}

#
# Allow SNS Topics to trigger Lambda
#
resource "aws_lambda_permission" "snsCanTriggerStartExportTask" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = module.start_export_task_lambda.lambda_function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.rdsSnapshotsEvents.arn
}

resource "aws_lambda_permission" "snsCanTriggerMonitorExportTask" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = module.monitor_export_task_lambda.lambda_function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.rdsSnapshotsEvents.arn
}
