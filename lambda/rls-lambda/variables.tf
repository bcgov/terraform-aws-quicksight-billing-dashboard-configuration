
variable "aws_region" {
  description = "AWS region to deploy resources"
  default     = "ca-central-1"
}


variable "operations_account_id" {
  description = "Account id of the aws management (or) management account"
  type        = string
}

variable "management_account_id" {
  description = "Account id of the aws management (or) management account"
  type        = string
}

variable "destination_cur_bucket_name" {
  description = "Name of the bucket where the Cost and Usage reports are replicated. "
  type        = string
}

variable "cur_table_name" {
  description = "Name of the cur table in Glue "
  type        = string
}
variable "QuickSightUser" {
  description = "User name of QuickSight user (as displayed in QuickSight admin panel). The RLS DataSource and DataSet will be owned by this user."
  type        = string
}

variable "RLSLambdaScheduleExpression" {
  description = "The cron schedule for the RLS Lambda to run. Default is every 30 mins, 8am-5:30pm MON-FRI"
  type        = string
  default     = "cron(0/30 8-17 ? * MON-FRI *)"
}

variable "RLSLambdaTimezone" {
  description = "The timezone for the RLSLambda EventBridge scheduler"
  type        = string
  default     = "Canada/Pacific"
}

variable "AccountMapLambdaScheduleExpression" {
  description = "The cron schedule for the Account Map Lambda to run. Default is every weekday at 8am."
  type        = string
  default     = "cron(0 8 ? * MON-FRI *)"
}

variable "AccountMapLambdaTimezone" {
  description = "The timezone for the Account Map Lambda EventBridge scheduler"
  type        = string
  default     = "Canada/Pacific"
}

variable "billing_group_regex" {
  description = "Regex to match billing group names in the AWS account. This is used to filter accounts for RLS."
  type        = string
}

variable "quicksight_reader_group_name" {
  description = "Name of the QuickSight Reader group in IAM Identity Center"
  type        = string
}

variable "quicksight_dashboard_admin_group_name" {
  description = "Name of the Quicksight dashboard admin group in IAM Identity Center"
  type        = string
}

variable "CUDOSv5DashboardURL" {
  description = "Url of the CUDOSv5Dashboard"
  type        = string
}


variable "CostIntelligenceDashboardURL" {
  description = "Url of the Cost Intelligence Dashboard"
  type        = string
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for alarms"
  type        = string
}
