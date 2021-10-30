#
# Create an event rule to listen for RDS DB Cluster Snapshot Events
#
resource "aws_cloudwatch_event_rule" "rdsSnapshotCreation" {
  name        = "${local.prefix}rds-snapshot-creation"
  description = "RDS Snapshot Creation"

  event_pattern = <<PATTERN
{
  "source": [
    "aws.rds"
  ],
  "detail-type": [
    "RDS DB Cluster Snapshot Event"
  ]
}
PATTERN

  tags = merge({ Name = "${local.prefix}rds-snapshot-creation" }, var.tags)
}

#
# Send the events captured by the rule above to an SNS Topic
#
resource "aws_cloudwatch_event_target" "rdsSnapshotCreationTopic" {
  rule      = aws_cloudwatch_event_rule.rdsSnapshotCreation.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.rdsSnapshotsEvents.arn
}
