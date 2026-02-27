resource "aws_cloudwatch_metric_alarm" "rls_lambda_failed_executions" {
  alarm_name          = "BCGOV-LZA-RLS-lamdbda-failed-executions"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "0"
  datapoints_to_alarm = "1"
  treat_missing_data  = "notBreaching"
  alarm_description   = "Monitor RLS Lambda for errors"
  alarm_actions       = [var.sns_topic_arn]
  dimensions = {
    FunctionName = aws_lambda_function.rls_lambda.function_name
  }
}

resource "aws_cloudwatch_metric_alarm" "account_map_lambda_failed_executions" {
  alarm_name          = "BCGOV-LZA-account-map-lamdbda-failed-executions"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "0"
  datapoints_to_alarm = "1"
  treat_missing_data  = "notBreaching"
  alarm_description   = "Monitor account mapping Lambda for errors"
  alarm_actions       = [var.sns_topic_arn]
  dimensions = {
    FunctionName = aws_lambda_function.account_mapping_lambda.function_name
  }
}
