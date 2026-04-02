# CID Data Exports Destination
# Deploy in Operations account

resource "aws_cloudformation_stack" "cid_dataexports_destination" {
  provider = aws.Operations

  name         = "BCGOV-LZA-CID-DataExports-Destination"
  template_url = local.data_exports_template_url
  capabilities = local.common_capabilities

  parameters = {
    DestinationAccountId = var.operations_account_id
    SourceAccountIds     = local.source_account_ids_csv
    ResourcePrefix       = var.resource_prefix
    ManageCUR2           = "yes"
    ManageFOCUS          = "no"
    ManageCOH            = "no"
    EnableSCAD           = "no"
    RolePath             = var.role_path
    CUR2TimeGranularity  = var.time_granularity
  }

  tags = local.common_tags

  timeouts {
    create = "45m"
    update = "45m"
    delete = "45m"
  }
}

# CID Data Exports Source
# Deploy in Management account

resource "aws_cloudformation_stack" "cid_dataexports_source" {
  provider = aws.Management

  name         = "BCGOV-LZA-CID-DataExports-Source"
  template_url = local.data_exports_template_url
  capabilities = local.common_capabilities

  parameters = {
    DestinationAccountId = var.operations_account_id
    SourceAccountIds     = local.source_account_ids_csv
    ResourcePrefix       = var.resource_prefix
    ManageCUR2           = "yes"
    ManageFOCUS          = "no"
    ManageCOH            = "no"
    EnableSCAD           = "no"
    RolePath             = var.role_path
    CUR2TimeGranularity  = var.time_granularity
  }

  tags = local.common_tags

  timeouts {
    create = "45m"
    update = "45m"
    delete = "45m"
  }

  depends_on = [
    aws_cloudformation_stack.cid_dataexports_destination
  ]
}


# Cloud Intelligence Dashboards
# Deploy in Operations account
resource "aws_cloudformation_stack" "cid_dashboards" {
  provider = aws.Operations

  name         = "BCGOV-LZA-Cloud-Intelligence-Dashboards"
  template_url = local.cid_dashboard_template_url
  capabilities = local.common_capabilities

  parameters = {
    PrerequisitesQuickSight            = "yes"
    PrerequisitesQuickSightPermissions = "yes"
    QuickSightUser                     = var.QuickSightUser

    # CUR 2.0
    CURVersion         = "2.0"
    KeepLegacyCURTable = "no"

    # Dashboards
    DeployCUDOSv5                   = var.deploy_cudos_v5
    DeployCUDOSDashboard            = "no"
    DeployCostIntelligenceDashboard = var.deploy_cost_intelligence_dashboard
    DeployKPIDashboard              = var.deploy_kpi_dashboard

  }

  tags = merge(
    local.common_tags,
    {
      DashboardType = "Foundational"
      DashboardId   = "cloud-intelligence-dashboards"
    }
  )

  timeouts {
    create = "60m"
    update = "60m"
    delete = "60m"
  }

  depends_on = [
    aws_cloudformation_stack.cid_dataexports_destination,
    aws_cloudformation_stack.cid_dataexports_source
  ]
}

module "rls_lambda" {
  source = "./lambda/rls-lambda"
  providers = {
    aws = aws.Operations
  }
  QuickSightUser                        = var.QuickSightUser
  management_account_id                 = var.management_account_id
  operations_account_id                 = var.operations_account_id
  destination_cur_bucket_name           = aws_cloudformation_stack.cid_dataexports_destination.outputs["AggregateBucketName"]
  cur_table_name                        = "cur2"
  billing_group_regex                   = var.billing_group_regex
  quicksight_reader_group_name          = var.quicksight_reader_group_name
  quicksight_dashboard_admin_group_name = var.quicksight_dashboard_admin_group_name
  CUDOSv5DashboardURL                   = aws_cloudformation_stack.cid_dashboards.outputs["CUDOSv5DashboardURL"]
  CostIntelligenceDashboardURL          = aws_cloudformation_stack.cid_dashboards.outputs["CostIntelligenceDashboardURL"]
  sns_topic_arn                         = var.sns_topic_arn
  depends_on                            = [aws_cloudformation_stack.cid_dashboards]
}
