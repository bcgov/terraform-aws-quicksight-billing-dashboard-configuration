locals {
  # Remove the trailing slash (if any) and then split the path
  path_parts = split("/", trimsuffix(var.CURBucketPath, "/"))

  # Extract the last segment of the CURBucketPath using length and element
  last_segment = element(local.path_parts, length(local.path_parts) - 1)

  # Replace hyphens with underscores and convert to lowercase
  glue_table_name = lower(replace(local.last_segment, "-", "_"))
}


module "cid_dashboards" {
  source          = "github.com/aws-samples/aws-cudos-framework-deployment//terraform-modules/cid-dashboards?ref=0.2.46" # version locking
  stack_name      = "Cloud-Intelligence-Dashboards"
  template_bucket = aws_s3_bucket.destination_bucket.id
  stack_parameters = {
    "PrerequisitesQuickSight"            = "yes"
    "PrerequisitesQuickSightPermissions" = "yes"
    "CURBucketPath"                      = var.CURBucketPath
    "DeployCUDOSv5"                      = "yes"
    "DeployCostIntelligenceDashboard"    = "yes"
    "QuickSightUser"                     = var.QuickSightUser
  }
}

output "glue_table_name" {
  value = local.glue_table_name
}
