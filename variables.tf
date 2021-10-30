#regex snapshots bucket name
locals {
  snapshots_bucket_arn = "arn:aws:s3:::${var.snapshots_bucket_name}"
  prefix               = var.prefix != null ? "${var.prefix}-" : ""
}

variable "prefix" {
  description = "Prefix that will be used for naming resources."
  type        = string
  default     = null
}

variable "database_names" {
  description = "The names of the databases whose snapshots we want to export to S3. Comma-separated values), ex: 'db-cluster1, db-cluster2'"
  type        = string
  default     = null
}

variable "snapshots_bucket_name" {
  description = "The name of the bucket where the RDS snapshots will be exported to."
  type        = string
  default     = null
}

variable "snapshots_bucket_prefix" {
  description = "The Amazon S3 bucket prefix to use as the file name and path of the exported snapshot. For example, use the prefix exports/2019/"
  type        = string
  default     = null
}

variable "rds_event_ids" {
  description = <<DOC
RDS (CloudWatch) Event ID that will trigger the calling of RDS Start Export Task API:
- Automated snapshots of Aurora RDS: RDS-EVENT-0169
- Automated snapshots of non-Aurora RDS: RDS-EVENT-0091
Only automated backups of either RDS Aurora and RDS non-Aurora are supported.
Ref: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_Events.Messages.html#USER_Events.Messages.snapshot
Ref: https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/USER_Events.Messages.html#USER_Events.Messages.cluster-snapshot
DOC
  type        = string
  default     = "RDS-EVENT-0091, RDS-EVENT-0169"
}

variable "create_customer_kms_key" {
  description = "Create customer managed KMS key which is used for encrypting the exported snapshots on S3. If set to 'false', then 'customer_kms_key_arn' is used."
  type        = bool
  default     = false
}

variable "customer_kms_key_arn" {
  description = "The ARN of customer managed key used for RDS export encryption. Mandatory if 'create_customer_kms_key' is set to false. arn:aws:kms:<region>:<accountID>:key/<key-id>"
  type        = string
  default     = null
}

variable "create_notifications_topic" {
  description = "Create new SNS notifications topic which will be used for publishing notifications messages."
  type        = bool
  default     = true
}

variable "notifications_topic_arn" {
  description = "The ARN of an SNS Topic which will be used for publishing notifications messages. Required if 'create_notifications_topic' is set to 'false'."
  type        = string
  default     = null
}

variable "log_level" {
  description = "The log level of the Lambda function."
  type        = string
  default     = "INFO"
}

variable "tags" {
  description = "(Optional) A mapping of tags to assign to the bucket."
  type        = map(string)
  default     = {}
}
