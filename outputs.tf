output "cid_dataexports_destination_stack_id" {
  description = "CID Data Exports destination stack ID."
  value       = aws_cloudformation_stack.cid_dataexports_destination.id
}

output "cid_dataexports_source_stack_id" {
  description = "CID Data Exports source stack ID."
  value       = aws_cloudformation_stack.cid_dataexports_source.id
}

output "cid_dashboards_stack_id" {
  description = "CID dashboards stack ID."
  value       = aws_cloudformation_stack.cid_dashboards.id
}

output "cid_dashboards_outputs" {
  description = "Outputs from the Cloud-Intelligence-Dashboards stack."
  value       = aws_cloudformation_stack.cid_dashboards.outputs
}

output "cid_dataexports_destination_outputs" {
  description = "Outputs from the CID Data Exports destination stack."
  value       = aws_cloudformation_stack.cid_dataexports_destination.outputs
}

output "cid_dataexports_source_outputs" {
  description = "Outputs from the CID Data Exports source stack."
  value       = aws_cloudformation_stack.cid_dataexports_source.outputs
}
