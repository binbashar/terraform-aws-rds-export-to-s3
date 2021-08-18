variable "prefix" {
  description = "Prefix that will be used for naming resources."
  type        = string
  default     = null
}

variable "database_name" {
  description = "The name of the database whose snapshots we want to export to S3."
  type        = string
  default     = null
}

variable "snapshots_bucket_arn" {
  description = "The ARN of the bucket where the RDS snapshots will be exported to."
  type        = string
  default     = null
}

variable "snapshots_bucket_name" {
  description = "The name of the bucket where the RDS snapshots will be exported to."
  type        = string
  default     = null
}

variable "rds_event_id" {
  description = <<DOC
RDS (CloudWatch) Event ID that will trigger the calling of RDS Start Export Task API:
- Automated snapshots of Aurora RDS: RDS-EVENT-0169
- Automated snapshots of non-Aurora RDS: RDS-EVENT-0091
Only automated backups of either RDS Aurora and RDS non-Aurora are supported.
Ref: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_Events.Messages.html#USER_Events.Messages.snapshot
DOC
  type        = string
}

variable "notifications_topic_arn" {
  description = "The ARN of an SNS Topic which will be used for publishing notifications messages."
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
