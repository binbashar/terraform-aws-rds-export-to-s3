output "start_export_task_lambda_function_arn" {
  description = "Start Export Task Lambda Function ARN"
  value       = module.start_export_task_lambda.lambda_function_arn
}

output "start_export_task_lambda_role_arn" {
  description = "Start Export Task Lambda Role ARN"
  value       = module.start_export_task_lambda.lambda_role_arn
}

output "monitor_export_task_lambda_function_arn" {
  description = "Start Export Task Monitor Lambda Function ARN"
  value       = module.monitor_export_task_lambda.lambda_function_arn
}

output "monitor_export_task_lambda_role_arn" {
  description = "Start Export Task Monitor Lambda Role ARN"
  value       = module.monitor_export_task_lambda.lambda_role_arn
}

output "snapshots_export_encryption_key_arn" {
  description = "Snapshots Export Encryption Key ARN"
  value       = var.create_customer_kms_key ? aws_kms_key.snapshotExportEncryptionKey[0].arn : var.customer_kms_key_arn
}

output "snapshots_events_sns_topics_arn" {
  description = "RDS Snapshots Events SNS Topics ARN"
  value       = aws_sns_topic.rdsSnapshotsEvents.arn
}

output "snapshots_events_export_monitor_sns_topics_arn" {
  description = "RDS Snapshots Export Monitor Events SNS Topics ARN"
  value       = var.create_notifications_topic ? aws_sns_topic.exportMonitorNotifications[0].arn : var.notifications_topic_arn
}
