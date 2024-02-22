output "quicksight_admin_role_arn" {
  value = aws_iam_role.quicksight_admin.arn
}

output "quicksight_reader_role_arn" {
  value = aws_iam_role.quicksight_reader.arn
}

output "cur_replication_bucket_name" {
  value = aws_s3_bucket.destination_bucket.id
}
