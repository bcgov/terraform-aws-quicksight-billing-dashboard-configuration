locals {
  common_capabilities = [
    "CAPABILITY_IAM",
    "CAPABILITY_NAMED_IAM"
  ]

  common_tags = merge(
    {
      Name = "BCGOV-LZA"
    }
  )

  # AWS-managed official template URLs
  data_exports_template_url  = "https://aws-managed-cost-intelligence-dashboards.s3.amazonaws.com/cfn/data-exports/${var.cid_data_export_version}/data-exports-aggregation.yaml"
  cid_dashboard_template_url = "https://aws-managed-cost-intelligence-dashboards.s3.amazonaws.com/cfn/${var.cid_dashboard_version}/cid-cfn.yml"

  source_account_ids_csv = var.management_account_id
}
