output "quicksight_admin_role_arn" {
  description = "Arn of the Quicksight Admin role created"
  value = aws_iam_role.quicksight_admin.arn
}

output "quicksight_reader_role_arn" {
  description = "Arn of the Quicksight reader role created"
  value = aws_iam_role.quicksight_reader.arn
}

output "cur_replication_bucket_name" {
  description = "Name of the bucket created in the destination account to replicate the CUR data from management account"
  value = aws_s3_bucket.destination_bucket.id
}
