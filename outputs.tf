output "quicksight_admin_role_arn" {
  value = aws_iam_role.quicksight_admin.arn
}

output "quicksight_reader_role_arn" {
  value = aws_iam_role.quicksight_reader.arn
}