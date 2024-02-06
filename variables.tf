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

