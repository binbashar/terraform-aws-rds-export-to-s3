#
# This key will be used for encrypting snapshots exported to S3
#
resource "aws_kms_key" "snapshotExportEncryptionKey" {
  count       = var.create_customer_kms_key ? 1 : 0
  description = "Snapshot Export Encryption Key"
  tags        = merge({ Name = "${local.prefix}kms-rds-snapshot-key${local.postfix}" }, var.tags)
  policy      = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Allow administration of the key to the account",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
            },
            "Action": "kms:*",
            "Resource": "*"
        },
        {
            "Sid": "Allow usage of the key",
            "Effect": "Allow",
            "Principal": {
                "AWS": "${module.start_export_task_lambda.lambda_role_arn}"
            },
            "Action": [
                "kms:Encrypt",
                "kms:Decrypt",
                "kms:ReEncrypt*",
                "kms:GenerateDataKey*",
                "kms:DescribeKey"
            ],
            "Resource": "*"
        },
        {
            "Sid": "Allow grants on the key",
            "Effect": "Allow",
            "Principal": {
                "AWS": "${module.start_export_task_lambda.lambda_role_arn}"
            },
            "Action": [
                "kms:CreateGrant",
                "kms:ListGrants",
                "kms:RevokeGrant"
            ],
            "Resource": "*",
            "Condition": {
                "Bool": { "kms:GrantIsForAWSResource": "true" }
            }
        }
    ]
}
POLICY
}

#
# Key alias
#
resource "aws_kms_alias" "snapshotExportEncryptionKey" {
  count         = var.create_customer_kms_key ? 1 : 0
  name          = "alias/${local.prefix}rds-snapshot-export${local.postfix}"
  target_key_id = aws_kms_key.snapshotExportEncryptionKey[0].key_id
}
