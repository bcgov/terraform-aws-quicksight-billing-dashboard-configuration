
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

variable "QuickSightUser" {
  description = "User name of QuickSight user (as displayed in QuickSight admin panel). The RLS DataSource and DataSet will be owned by this user."
  type        = string
}

variable "billing_group_regex" {
  description = "Regex to match billing group names in the AWS account. This is used to filter accounts for RLS."
  type        = string
}

variable "quicksight_reader_group_name" {
  description = "Name of the QuickSight Reader group in IAM Identity Center"
  type        = string
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for alarms"
  type        = string
}
