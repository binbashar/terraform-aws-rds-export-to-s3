<a href="https://github.com/binbashar">
    <img src="https://raw.githubusercontent.com/binbashar/le-ref-architecture-doc/master/docs/assets/images/logos/binbash-leverage-banner.png" width="1032" align="left" alt="Binbash"/>
</a>
<br clear="left"/>

# Terraform Module: RDS Snapshots Export To S3

## Brief
Terraform module that deploys Lambda functions that take care of triggering and monitoring exports of RDS snapshots to S3.

## Design
A Lambda function takes care of triggering the RDS Start Export Task for the given database name. The snapshots will be exported to the given S3 bucket.

Another Lambda function is only interested in RDS Export Task events that match a given database name. Whenever a match is detected, a message will be published in the given SNS topic which you can use to trigger other components. E.g. a Lambda function that sends notifications to Slack.

A single CloudWatch Event Rule takes care of listening for RDS Snapshots Events in order to call the aforementioned Lambda functions.

<div align="left">
  <img src="https://raw.githubusercontent.com/binbashar/terraform-aws-rds-export-to-s3/master/assets/rds-export-to-s3.png" alt="leverage" width="400"/>
</div>

## Important considerations
* Please note, that only customer managed keys (CMK) are allowed.
* Either `customer_kms_key_arn` provided key is used for exported snapshots encryption or new CMK created with `create_customer_kms_key` enabled
* Since the module (optionally) creates its own KMS CMK, keep that in mind regarding KMS pricing; not only regarding the pricing of a single key, but also things like key rotations/versions and KMS API requests.
* The module requires you to provide the S3 bucket that will be used for storing the exported snapshots. The good thing about this is that you are able to configure the bucket in any way you need. E.g. replication, lifecycle, locking, and so on.
* The module can create an export monitor SNS notification topic, also existing SNS topics are supported via `notifications_topic_arn` variable.
* Multi-region support via terraform providers.
* If triggering from manual snapshots, the snapshot must be named as `rds-<database-name>-<timestamp>` with timestamp of format eg '2023-08-09-18-07'.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.19 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3.19 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_monitor_export_task_lambda"></a> [monitor\_export\_task\_lambda](#module\_monitor\_export\_task\_lambda) | github.com/terraform-aws-modules/terraform-aws-lambda | v2.23.0 |
| <a name="module_start_export_task_lambda"></a> [start\_export\_task\_lambda](#module\_start\_export\_task\_lambda) | github.com/terraform-aws-modules/terraform-aws-lambda | v2.23.0 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_event_rule.rdsSnapshotCreation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.rdsSnapshotCreationTopic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_iam_policy.rdsMonitorExportTaskLambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.rdsStartExportTaskLambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.rdsSnapshotExportTask](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.rdsSnapshotExportToS3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_kms_alias.snapshotExportEncryptionKey](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.snapshotExportEncryptionKey](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_lambda_permission.snsCanTriggerMonitorExportTask](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_lambda_permission.snsCanTriggerStartExportTask](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_sns_topic.exportMonitorNotifications](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic.rdsSnapshotsEvents](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_policy.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_policy) | resource |
| [aws_sns_topic_subscription.lambdaRdsSnapshotToS3Exporter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [aws_sns_topic_subscription.lambdaRdsSnapshotToS3Monitor](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_create_customer_kms_key"></a> [create\_customer\_kms\_key](#input\_create\_customer\_kms\_key) | Create customer managed KMS key which is used for encrypting the exported snapshots on S3. If set to 'false', then 'customer\_kms\_key\_arn' is used. | `bool` | `false` | no |
| <a name="input_create_notifications_topic"></a> [create\_notifications\_topic](#input\_create\_notifications\_topic) | Create new SNS notifications topic which will be used for publishing notifications messages. | `bool` | `true` | no |
| <a name="input_customer_kms_key_arn"></a> [customer\_kms\_key\_arn](#input\_customer\_kms\_key\_arn) | The ARN of customer managed key used for RDS export encryption. Mandatory if 'create\_customer\_kms\_key' is set to false. arn:aws:kms:<region>:<accountID>:key/<key-id> | `string` | `null` | no |
| <a name="input_database_names"></a> [database\_names](#input\_database\_names) | The names of the databases whose snapshots we want to export to S3. Comma-separated values), ex: 'db-cluster1, db-cluster2' | `string` | `null` | yes |
| <a name="input_log_level"></a> [log\_level](#input\_log\_level) | The log level of the Lambda function. | `string` | `"INFO"` | no |
| <a name="input_notifications_topic_arn"></a> [notifications\_topic\_arn](#input\_notifications\_topic\_arn) | The ARN of an SNS Topic which will be used for publishing notifications messages. Required if 'create\_notifications\_topic' is set to 'false'. | `string` | `null` | no |
| <a name="input_postfix"></a> [postfix](#input\_postfix) | Postfix that will be used for naming resources. 'resouce-name-<postfix>'. | `string` | `null` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | Prefix that will be used for naming resources. '<prefix>resouce-name'. | `string` | `null` | no |
| <a name="input_rds_event_ids"></a> [rds\_event\_ids](#input\_rds\_event\_ids) | RDS (CloudWatch) Event ID that will trigger the calling of RDS Start Export Task API:<br>- Automated snapshots of Aurora RDS: RDS-EVENT-0169<br>- Manual snapshots of Aurora RDS: RDS-EVENT-0075<br>- Automated snapshots of non-Aurora RDS: RDS-EVENT-0091<br>- Manual snapshots of non-Aurora RDS: RDS-EVENT-0042<br>Automated and/or manual backups of either RDS Aurora and RDS non-Aurora are supported.<br>Ref: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_Events.Messages.html#USER_Events.Messages.snapshot<br>Ref: https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/USER_Events.Messages.html#USER_Events.Messages.cluster-snapshot | `string` | `"RDS-EVENT-0091, RDS-EVENT-0169"` | no |
| <a name="input_snapshots_bucket_name"></a> [snapshots\_bucket\_name](#input\_snapshots\_bucket\_name) | The name of the bucket where the RDS snapshots will be exported to. | `string` | `null` | yes |
| <a name="input_snapshots_bucket_prefix"></a> [snapshots\_bucket\_prefix](#input\_snapshots\_bucket\_prefix) | The Amazon S3 bucket prefix to use as the file name and path of the exported snapshot. For example, use the prefix exports/2019/ | `string` | `null` | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) A mapping of tags to assign to the bucket. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_monitor_export_task_lambda_function_arn"></a> [monitor\_export\_task\_lambda\_function\_arn](#output\_monitor\_export\_task\_lambda\_function\_arn) | Start Export Task Monitor Lambda Function ARN |
| <a name="output_monitor_export_task_lambda_role_arn"></a> [monitor\_export\_task\_lambda\_role\_arn](#output\_monitor\_export\_task\_lambda\_role\_arn) | Start Export Task Monitor Lambda Role ARN |
| <a name="output_snapshots_events_export_monitor_sns_topics_arn"></a> [snapshots\_events\_export\_monitor\_sns\_topics\_arn](#output\_snapshots\_events\_export\_monitor\_sns\_topics\_arn) | RDS Snapshots Export Monitor Events SNS Topics ARN |
| <a name="output_snapshots_events_sns_topics_arn"></a> [snapshots\_events\_sns\_topics\_arn](#output\_snapshots\_events\_sns\_topics\_arn) | RDS Snapshots Events SNS Topics ARN |
| <a name="output_snapshots_export_encryption_key_arn"></a> [snapshots\_export\_encryption\_key\_arn](#output\_snapshots\_export\_encryption\_key\_arn) | Snapshots Export Encryption Key ARN |
| <a name="output_start_export_task_lambda_function_arn"></a> [start\_export\_task\_lambda\_function\_arn](#output\_start\_export\_task\_lambda\_function\_arn) | Start Export Task Lambda Function ARN |
| <a name="output_start_export_task_lambda_role_arn"></a> [start\_export\_task\_lambda\_role\_arn](#output\_start\_export\_task\_lambda\_role\_arn) | Start Export Task Lambda Role ARN |
<!-- END_TF_DOCS -->