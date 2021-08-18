#
# This role is used by RDS Start Export Task
#
resource "aws_iam_role" "rdsSnapshotExportTask" {
  name               = "${var.prefix}-snapshot-export-task"
  assume_role_policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "export.rds.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
POLICY
}

#
# Allow RDS Start Export Task to write the snapshot on the S3 bucket
#
resource "aws_iam_role_policy" "rdsSnapshotExportToS3" {
  name   = "${var.prefix}-rds-snapshot-export-to-s3"
  role   = aws_iam_role.rdsSnapshotExportTask.id
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "ExportPolicy",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject*",
                "s3:ListBucket",
                "s3:GetObject*",
                "s3:DeleteObject*",
                "s3:GetBucketLocation"
            ],
            "Resource": [
                "${var.snapshots_bucket_arn}",
                "${var.snapshots_bucket_arn}/*"
            ]
        }
    ]
}
POLICY
}

#
# Lambda Permissions: Start Export Task
#
resource "aws_iam_policy" "rdsStartExportTaskLambda" {
  name   = "${var.prefix}-rds-snapshot-exporter-lambda"
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "rds:StartExportTask",
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": "iam:PassRole",
            "Resource": ["${aws_iam_role.rdsSnapshotExportTask.arn}"],
            "Effect": "Allow"
        }
    ]
}
POLICY
}

#
# Lambda Permissions: Export Task Monitor
#
resource "aws_iam_policy" "rdsMonitorExportTaskLambda" {
  name   = "${var.prefix}-rds-snapshot-exporter-monitor-lambda"
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sns:Publish",
            "Resource": ["${var.notifications_topic_arn}"],
            "Effect": "Allow"
        }
    ]
}
POLICY
}
