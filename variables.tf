
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

variable "cid_data_export_version" {
  type        = string
  description = "Version of the AWS-managed Data Exports template."
  default     = "0.10.0"
}

variable "cid_dashboard_version" {
  type        = string
  description = "Version of the AWS-managed CID dashboard template."
  default     = "4.4.10"
}

variable "resource_prefix" {
  type        = string
  description = "Prefix used by CID-created resources."
  default     = "cid"
}

variable "role_path" {
  type        = string
  description = "IAM role path for CID-created roles."
  default     = "/"
}

variable "time_granularity" {
  type        = string
  description = "Data Exports granularity."
  default     = "HOURLY"

  validation {
    condition     = contains(["HOURLY", "DAILY", "MONTHLY"], var.time_granularity)
    error_message = "time_granularity must be HOURLY, DAILY, or MONTHLY."
  }
}

variable "deploy_cudos_v5" {
  type        = string
  description = "Deploy CUDOS v5 dashboard."
  default     = "yes"

  validation {
    condition     = contains(["yes", "no"], var.deploy_cudos_v5)
    error_message = "deploy_cudos_v5 must be yes or no."
  }
}

variable "deploy_cost_intelligence_dashboard" {
  type        = string
  description = "Deploy Cost Intelligence dashboard."
  default     = "yes"

  validation {
    condition     = contains(["yes", "no"], var.deploy_cost_intelligence_dashboard)
    error_message = "deploy_cost_intelligence_dashboard must be yes or no."
  }
}

variable "deploy_kpi_dashboard" {
  type        = string
  description = "Deploy KPI dashboard."
  default     = "yes"

  validation {
    condition     = contains(["yes", "no"], var.deploy_kpi_dashboard)
    error_message = "deploy_kpi_dashboard must be yes or no."
  }
}

variable "permissions_boundary" {
  type        = string
  description = "Optional IAM permissions boundary ARN."
  default     = ""
}

variable "quicksight_reader_group_name" {
  description = "Name of the QuickSight Reader group in IAM Identity Center"
  type        = string
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for alarms"
  type        = string
}
