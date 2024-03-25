
variable "aws_region" {
  description = "AWS region to deploy resources"
  default     = "ca-central-1"
}

variable "kc_terraform_auth_client_id" {
  description = "Id of client used to connect to keycloack"
}

variable "kc_terraform_auth_client_secret" {
  description = "secret of client used to connect to keycloack"
}

variable "kc_base_url" {
  description = "Base URL for Keycloak"
}

variable "kc_realm" {
  description = "realm name of the Keycloak"
}

variable "rls_lambda_client_id" {
  description = "Id of the rls lambda client created"
  type        = string
  default     = "rls-lambda"
}

variable "rls_lambda_client_name" {
  description = "Name of the rls lambda client created"
  type        = string
  default     = "RLS-Lambda-Client"
}

variable "rls_lambda_client_roles" {
  description = "List of Keycloak role names"
  type        = list(string)
  default     = ["query-clients", "query-groups", "query-users", "view-clients", "view-users"]
}

variable "quicksight_client_id" {
  description = "Id of the quicksight client created"
  type        = string
  default     = "Quicksight"
}

variable "quicksight_client_name" {
  description = "Name of the quicksight client created"
  type        = string
  default     = "Quicksight"
}


variable "aws_saml_idp_arn" {
  description = "Name of the saml identity provider in the aws account"
  type        = string
}

variable "session_duration" {
  description = "Session duration length in seconds"
  type        = number
  default     = 10800 # 3 hours
}

variable "idp_initiated_sso_relay_state" {
  description = "Url to redirect once the authentication is completed"
  type        = string
}

variable "idp_initiated_sso_url_name" {
  description = "URL fragment name to reference client when you want to do idp initiated sso "
  type        = string
}

variable "aws_master_account_id" {
  description = "Account id of the aws master (or) management account"
  type        = string
}

variable "operations_account_id" {
  description = "Account id of the aws master (or) management account"
  type        = string
}

variable "management_cur_bucket_name" {
  description = "Name of the management account bucket where the CUR already exists"
  type        = string
}

variable "cur_export_bucket_name"{
  description = "Name of the bucket created in the management account to store exported cur reports"
  type = string
}

variable "master_account_kms_key_alias" {
  description = "Alias of the master account kms encryption key"
  type        = string
}

variable "operations_account_kms_key_alias" {
  description = "Alias of the operations account kms encryption key"
  type        = string
}

variable "cur_replication_bucket_name" {
  description = "Name of the bucket where the Cost and Usage reports are replicated. "
  type        = string
}

variable "iam_replication_role_name" {
  description = "Name of the Iam role used to do the replication."
  type        = string
}

variable "iam_replication_policy_name" {
  description = "Name of the Iam policy created and attached to the iam replication role mentioned above."
  type        = string
}


variable "ClientIdKey" {
  description = "The name of the key within the above secret that points to the Client ID"
  type        = string
  default     = "client_id"
}

variable "ClientSecretKey" {
  description = "The name of the key within the above secret that points to the Client Secret"
  type        = string
  default     = "client_secret"
}



variable "KeycloakURL" {
  type        = string
  description = "The base URL (without http(s)://) of your Keycloak deployment. The Keycloak URL must not contain http(s)://."
}


variable "AWSClientName" {
  description = "The name of the AWS client configured in Keycloak"
  type        = string
  default     = "urn:amazon:webservices"
}

variable "QuickSightUser" {
  description = "User name of QuickSight user (as displayed in QuickSight admin panel). The RLS DataSource and DataSet will be owned by this user."
  type        = string
}

variable "RLSLambdaScheduleExpression" {
  description = "The cron schedule for the RLS Lambda to run. Default is every 30 mins, 8am-5:30pm MON-FRI"
  type        = string
  default     = "cron(0/30 8-17 ? * MON-FRI *)"
}

variable "RLSLambdaTimezone" {
  description = "The timezone for the RLSLambda EventBridge scheduler"
  type        = string
  default     = "Canada/Pacific"
}

variable "AccountMapLambdaScheduleExpression" {
  description = "The cron schedule for the Account Map Lambda to run. Default is every weekday at 8am."
  type        = string
  default     = "cron(0 8 ? * MON-FRI *)"
}

variable "AccountMapLambdaTimezone" {
  description = "The timezone for the Account Map Lambda EventBridge scheduler"
  type        = string
  default     = "Canada/Pacific"
}

variable "bcgov_roles_access" {
  description = "Name of the Bc gov role that is needed to get access to the Quicksight dashboards"
  type        = string
}

variable "CURBucketPath" {
  description = "S3 path for CUR data.In general, you want to navigate to the folder just before the year partition folders. In this example, the next folder in this path would be year=2024/. Example: s3://<Bucket Name>/<Path>"
  type        = string
}