# Deployment of RLS to limit user's view onto QuickSight dashboards
# Rls table


data "aws_ssoadmin_instances" "iam_identity_center_instance" {}

resource "aws_glue_catalog_table" "rls_glue_table" {
  name          = "rls"
  description   = "CUDOSv5 Dashboard URL: ${var.CUDOSv5DashboardURL}, Cost Intelligence Dashboard URL: ${var.CostIntelligenceDashboardURL}"
  database_name = "cid_cur"
  catalog_id    = var.operations_account_id

  table_type = "EXTERNAL_TABLE"

  parameters = {
    classification = "csv"
  }

  storage_descriptor {
    columns {
      name = "username"
      type = "string"
    }
    columns {
      name = "account_id"
      type = "string"
    }
    # compressed        = false
    location          = "s3://${var.destination_cur_bucket_name}/rls/"
    input_format      = "org.apache.hadoop.mapred.TextInputFormat"
    number_of_buckets = -1
    output_format     = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      parameters = {
        "separatorChar" = ","
        "quoteChar"     = "\""
      }
      serialization_library = "org.apache.hadoop.hive.serde2.OpenCSVSerde"
    }

    # stored_as_sub_directories = false
  }
}

# To create resources quicksight datasource and quicksight dataset

# Quicksight datasource
resource "aws_quicksight_data_source" "quicksight_data_source" {
  data_source_id = "rls_athena_data_source"
  name           = "RLS Athena Table Data Source"
  aws_account_id = var.operations_account_id

  parameters {
    athena {
      work_group = "CID"
    }
  }


  type = "ATHENA"
  permission {
    actions = [
      "quicksight:DescribeDataSource",
      "quicksight:DescribeDataSourcePermissions",
      "quicksight:PassDataSource",
      "quicksight:UpdateDataSource",
      "quicksight:DeleteDataSource",
      "quicksight:UpdateDataSourcePermissions"

    ]
    principal = "arn:aws:quicksight:${var.aws_region}:${var.operations_account_id}:user/default/${var.QuickSightUser}"
  }
  tags = {
    "CUDOSv5DashboardURL"          = var.CUDOSv5DashboardURL
    "CostIntelligenceDashboardURL" = var.CostIntelligenceDashboardURL
  }

  lifecycle {
    ignore_changes = [ssl_properties]
  }
}

# resource "null_resource" "delay_after_creation" {
#   depends_on = [aws_quicksight_data_source.quicksight_data_source]

#   provisioner "local-exec" {
#     command = "sleep 30" # Delay for 30 seconds
#   }
# }
# Quicksight dataset

resource "aws_quicksight_data_set" "rls_athena_data_set" {
  data_set_id    = "rls_athena_data_set"
  name           = "RLS"
  aws_account_id = var.operations_account_id
  import_mode    = "SPICE"

  physical_table_map {
    physical_table_map_id = "RLSGlueTable"
    relational_table {
      data_source_arn = aws_quicksight_data_source.quicksight_data_source.arn
      name            = aws_glue_catalog_table.rls_glue_table.name
      schema          = "cid_cur"
      input_columns {
        name = "username"
        type = "STRING"
      }
      input_columns {
        name = "account_id"
        type = "STRING"
      }
    }

  }

  permissions {
    actions = [
      "quicksight:DescribeDataSet",
      "quicksight:DescribeDataSetPermissions",
      "quicksight:PassDataSet",
      "quicksight:DescribeIngestion",
      "quicksight:ListIngestions",
      "quicksight:UpdateDataSet",
      "quicksight:DeleteDataSet",
      "quicksight:CreateIngestion",
      "quicksight:CancelIngestion",
      "quicksight:UpdateDataSetPermissions"
    ]
    principal = "arn:aws:quicksight:${var.aws_region}:${var.operations_account_id}:user/default/${var.QuickSightUser}"
  }
  lifecycle {
    ignore_changes = [refresh_properties]
  }
  depends_on = [aws_quicksight_data_source.quicksight_data_source]
}


resource "aws_iam_role" "RLSLambdaExecutionRole" {
  name = "RLSLambdaExecutionRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
  path = "/"
}

resource "aws_iam_role_policy_attachment" "rls_lambda_basic_execution" {
  role       = aws_iam_role.RLSLambdaExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "org_full_access" {
  role       = aws_iam_role.RLSLambdaExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/AWSOrganizationsFullAccess"
}

resource "aws_iam_role_policy" "QuickSightPermissions" {
  name = "QuickSightPermissions"
  role = aws_iam_role.RLSLambdaExecutionRole.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "quicksight:CreateIngestion"
        Effect   = "Allow"
        Resource = "arn:aws:quicksight:${var.aws_region}:${var.operations_account_id}:*"
      },
      {
        Action   = "quicksight:ListDatasets"
        Effect   = "Allow"
        Resource = "arn:aws:quicksight:${var.aws_region}:${var.operations_account_id}:dataset/*"
      },
      {
        Action   = "quicksight:ListIngestions"
        Effect   = "Allow"
        Resource = "arn:aws:quicksight:${var.aws_region}:${var.operations_account_id}:dataset/*/ingestion/*"
      },
    ]
  })
}

resource "aws_iam_role_policy" "IdentityStorePermissions" {
  name = "IdentityStorePermissions"
  role = aws_iam_role.RLSLambdaExecutionRole.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "identitystore:ListGroups",
        "identitystore:ListGroupMemberships",
        "identitystore:DescribeUser",
        "identitystore:CreateGroupMembership",
        "identitystore:DeleteGroupMembership"
      ]
      Effect   = "Allow"
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy" "S3Permissions" {
  name = "S3Permissions"
  role = aws_iam_role.RLSLambdaExecutionRole.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:PutObject",
          "s3:GetObject",
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::${var.destination_cur_bucket_name}",
          "arn:aws:s3:::${var.destination_cur_bucket_name}/*"
        ]
      },
    ]
  })
}

# Rls lambda function
data "archive_file" "rls_lambda_zip" {
  type        = "zip"
  source_file = "${path.root}/lambda/rls-lambda/index.py"
  output_path = "${path.root}/lambda/rls-lambda/index.zip"
}

resource "aws_lambda_function" "rls_lambda" {
  function_name = "RLSLambda"
  description   = "Creates the RLS CSV file and refreshes all datasets that use it"
  role          = aws_iam_role.RLSLambdaExecutionRole.arn
  handler       = "index.lambda_handler"
  runtime       = "python3.12"
  architectures = ["x86_64"]
  memory_size   = 128
  timeout       = 600

  filename         = data.archive_file.rls_lambda_zip.output_path
  source_code_hash = data.archive_file.rls_lambda_zip.output_base64sha256

  environment {
    variables = {
      DATASET_ARN                           = aws_quicksight_data_set.rls_athena_data_set.arn
      RLS_CSV_BUCKET_NAME                   = var.destination_cur_bucket_name
      AWS_ACCOUNT_ID                        = var.operations_account_id
      IDENTITY_STORE_ID                     = tolist(data.aws_ssoadmin_instances.iam_identity_center_instance.identity_store_ids)[0]
      BILLING_GROUP_REGEX                   = var.billing_group_regex
      QUICKSIGHT_READER_GROUP_NAME          = var.quicksight_reader_group_name
      QUICKSIGHT_DASHBOARD_ADMIN_GROUP_NAME = var.quicksight_dashboard_admin_group_name
    }
  }
  lifecycle {
    ignore_changes = [
      environment[0].variables["DATASET_ARN"]
    ]
  }
}

resource "aws_iam_role" "lambda_schedule_role" {
  name = "RLSLambdaSchedulerRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "scheduler.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "invoke_rls_lambda" {
  name = "InvokeRLSLambda"
  role = aws_iam_role.lambda_schedule_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "lambda:InvokeFunction"
        Resource = aws_lambda_function.rls_lambda.arn
      },
    ]
  })
}

# AWS Scheduler resource 
resource "aws_scheduler_schedule" "rls_lambda_schedule" {
  name        = "RLSLambdaSchedule"
  description = "Runs the RLS Lambda function per the defined schedule"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = var.RLSLambdaScheduleExpression
  schedule_expression_timezone = var.RLSLambdaTimezone
  state                        = "ENABLED"

  target {
    arn      = aws_lambda_function.rls_lambda.arn
    role_arn = aws_iam_role.lambda_schedule_role.arn
  }
}


#AccountMappingTable
resource "aws_glue_catalog_table" "account_mapping_table" {
  name          = "account_mapping"
  description   = "CUDOSv5 Dashboard URL: ${var.CUDOSv5DashboardURL}, Cost Intelligence Dashboard URL: ${var.CostIntelligenceDashboardURL}"
  database_name = "cid_cur"
  catalog_id    = var.operations_account_id

  # table_type = "EXTERNAL_TABLE"

  parameters = {
    classification           = "csv"
    has_encrypted_data       = false
    "skip.header.line.count" = "1"
    delimiter                = ","
  }

  storage_descriptor {
    columns {
      name = "account_id"
      type = "string"
    }
    columns {
      name = "account_name"
      type = "string"
    }
    columns {
      name = "account_email_id"
      type = "string"
    }
    columns {
      name = "ministry_name"
      type = "string"
    }
    columns {
      name = "billing_group"
      type = "string"
    }

    compressed        = false
    location          = "s3://${var.destination_cur_bucket_name}/account-map/"
    input_format      = "org.apache.hadoop.mapred.TextInputFormat"
    number_of_buckets = -1
    output_format     = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      parameters = {
        "field.delim" = ","
      }
      serialization_library = "org.apache.hadoop.hive.serde2.OpenCSVSerde"
    }

    stored_as_sub_directories = false
  }
}


# Account mapping lambda execution role 
resource "aws_iam_role" "account_map_lambda_execution_role" {
  name = "AccountMapLambdaExecutionRole"
  path = "/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com",
        },
        Action = "sts:AssumeRole",
      },
    ],
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.account_map_lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "org_and_s3_permissions" {
  name = "OrgAndS3Permissions"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "organizations:ListAccounts",
          "organizations:ListTagsForResource",
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetObject",
        ],
        Resource = [
          "arn:aws:s3:::${var.destination_cur_bucket_name}",
          "arn:aws:s3:::${var.destination_cur_bucket_name}/*",
          "arn:aws:s3:::aws-athena-query-results-cid-${var.operations_account_id}-${var.aws_region}/*"
        ]
      },
      {
        Effect   = "Allow",
        Action   = "s3:GetBucketLocation",
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = "s3:PutObject",
        Resource = "arn:aws:s3:::aws-athena-query-results-cid-${var.operations_account_id}-${var.aws_region}/*"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "org_and_s3_permissions_attach" {
  role       = aws_iam_role.account_map_lambda_execution_role.name
  policy_arn = aws_iam_policy.org_and_s3_permissions.arn
}

# Athena and glue perms

resource "aws_iam_policy" "athena_and_glue_permissions" {
  name = "AthenaAndGluePermissions"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "athena:StartQueryExecution",
          "athena:GetQueryExecution",
        ],
        Resource = "arn:aws:athena:${var.aws_region}:${var.operations_account_id}:workgroup/CID",
      },
      {
        Effect = "Allow",
        Action = [
          "glue:UpdateTable",
          "glue:GetTable",
        ],
        Resource = [
          "arn:aws:glue:${var.aws_region}:${var.operations_account_id}:catalog",
          "arn:aws:glue:${var.aws_region}:${var.operations_account_id}:database/cid_cur",
          "arn:aws:glue:${var.aws_region}:${var.operations_account_id}:table/cid_cur/*",
        ],
      },
    ],
  })
}

resource "aws_iam_role_policy_attachment" "athena_and_glue_permissions_attach" {
  role       = aws_iam_role.account_map_lambda_execution_role.name
  policy_arn = aws_iam_policy.athena_and_glue_permissions.arn
}

# Account mapping lambda

data "archive_file" "account_map_lambda_zip" {
  type        = "zip"
  source_file = "${path.root}/lambda/account-map-lambda/index.js"
  output_path = "${path.root}/lambda/account-map-lambda/index.zip"
}

resource "aws_lambda_function" "account_mapping_lambda" {
  function_name = "AccountMappingLambda"
  description   = "Creates an Account Mapping CSV file that maps account Id's to their names and adds the Ministry Name and Billing Group information to Athena."
  role          = aws_iam_role.account_map_lambda_execution_role.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  architectures = ["x86_64"]
  memory_size   = 128
  timeout       = 300

  filename         = data.archive_file.account_map_lambda_zip.output_path
  source_code_hash = data.archive_file.account_map_lambda_zip.output_base64sha256

  environment {
    variables = {
      RLS_CSV_FOLDER_URI          = "s3://${var.destination_cur_bucket_name}/rls/"
      ACCOUNT_MAPPING_TABLE_NAME  = aws_glue_catalog_table.account_mapping_table.name
      CUR_TALBE_NAME              = var.cur_table_name
      COST_AND_USAGE_REPORT_TABLE = var.cur_table_name
    }
  }
}

# Role policy for account mapping lambda schedulr 
resource "aws_iam_role" "account_map_lambda_schedule_role" {
  name = "AccountMapLambdaSchedulerRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "scheduler.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "invoke_account_map_lambda" {
  name = "InvokeRLSLambda"
  role = aws_iam_role.account_map_lambda_schedule_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "lambda:InvokeFunction"
        Resource = aws_lambda_function.account_mapping_lambda.arn
      },
    ]
  })
}

# account map lambda scheduler
resource "aws_scheduler_schedule" "account_map_lambda_schedule" {
  name        = "AccountMapLambdaSchedule"
  description = "Runs the Account Mapping Lambda function per the defined schedule"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = var.AccountMapLambdaScheduleExpression
  schedule_expression_timezone = var.AccountMapLambdaTimezone
  state                        = "ENABLED"

  target {
    arn      = aws_lambda_function.account_mapping_lambda.arn
    role_arn = aws_iam_role.account_map_lambda_schedule_role.arn
  }
}
