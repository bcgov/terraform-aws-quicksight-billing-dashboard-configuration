module "cloud-setup-destination" {
  source          = "github.com/aws-samples/aws-cudos-framework-deployment//legacy-terraform/cur-setup-destination?ref=4.3.0" # version locking
  providers = {
    aws = aws.Operations
    aws.useast1 = aws.useast1-operations
  }
    source_account_ids     = ["${var.management_account_id}"]   # Comma-separated list of Payer account IDs
    create_cur             = false
    tags                      = {
      Name = "BCGOV-LZA"
    }
  }

  output "cur_bucket_arn" {
    description = "ARN of the S3 bucket receiving the CUR"
    value       = module.cloud-setup-destination.cur_bucket_arn
  }

  output "cur_bucket_name" {
    description = "Name of the S3 bucket receiving the CUR"
    value       = module.cloud-setup-destination.cur_bucket_name
  }

module "cloud-setup-source" {
  source          = "github.com/aws-samples/aws-cudos-framework-deployment//legacy-terraform/cur-setup-source?ref=4.3.0" # version locking
  providers = {
    aws = aws.Management
    aws.useast1 = aws.useast1-Management
  }
  destination_bucket_arn = module.cloud-setup-destination.cur_bucket_arn
    tags                      = {
      Name = "BCGOV-LZA"
    }
    depends_on = [module.cloud-setup-destination]
  }
    output "cur_report_arn" {
    description = "ARN of the Cost and Usage Report"
    value       = module.cloud-setup-source.cur_report_arn
  }

module "cid_dashboards" {
  source          = "github.com/aws-samples/aws-cudos-framework-deployment//legacy-terraform/cid-dashboards?ref=4.3.0" # version locking
  providers = {
    aws = aws.Operations
  }
  stack_name      = "Cloud-Intelligence-Dashboards"
  template_bucket = module.cloud-setup-destination.cur_bucket_name
  stack_parameters = {
    "PrerequisitesQuickSight"            = "yes"
    "PrerequisitesQuickSightPermissions" = "yes"
    CURVersion                           = "1.0"
    "QuickSightUser"                     = "${var.QuickSightUser}"
    "CURBucketPath"                      = "s3://${module.cloud-setup-destination.cur_bucket_name}/cur/${var.management_account_id}/cid-cur/cid-cur/"
    "DeployCUDOSv5"                      = "yes"
    "DeployCUDOSDashboard"               = "no"  
    "DeployCostIntelligenceDashboard"    = "yes"
    "DeployKPIDashboard"                 = "yes"
  }
    depends_on = [module.cloud-setup-destination]
  } 


module "rls_lambda" {
  source          = "./lambda/rls-lambda"
  providers = {
    aws = aws.Operations
  }
  QuickSightUser                     = var.QuickSightUser
  management_account_id                = var.management_account_id
  operations_account_id                = var.operations_account_id
  destination_cur_bucket_name          = module.cloud-setup-destination.cur_bucket_name  
  cur_table_name = replace(element(split("/", module.cloud-setup-source.cur_report_arn),-1), "-", "_")
  billing_group_regex = "${var.billing_group_regex}"
  quicksight_reader_group_name = "${var.quicksight_reader_group_name}"
  CUDOSv5DashboardURL          = module.cid_dashboards.stack_outputs["CUDOSv5DashboardURL"]
  CostIntelligenceDashboardURL    = module.cid_dashboards.stack_outputs["CostIntelligenceDashboardURL"]
  depends_on = [module.cid_dashboards]
  }  