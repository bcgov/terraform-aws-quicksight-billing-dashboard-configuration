locals {
  quicksight_roles = {
    admin  = aws_iam_role.quicksight_admin.arn
    reader = aws_iam_role.quicksight_reader.arn
  }
}

# Keycloak deployment
data "keycloak_realm" "realm" {
  realm = var.kc_realm
}

# Rls lambda client
resource "keycloak_openid_client" "rls_lambda_client" {
  client_id                           = var.rls_lambda_client_id
  name                                = var.rls_lambda_client_name
  realm_id                            = data.keycloak_realm.realm.id
  description                         = "Client for rls-lambda"
  enabled                             = true
  full_scope_allowed                  = false
  standard_flow_enabled               = false
  service_accounts_enabled            = true
  backchannel_logout_session_required = true
  access_type                         = "CONFIDENTIAL"
}
data "keycloak_openid_client" "realm_management" {
  realm_id  = data.keycloak_realm.realm.id
  client_id = "realm-management"
}

data "keycloak_role" "rls_lambda_roles" {
  for_each = toset(var.rls_lambda_client_roles)

  realm_id  = data.keycloak_realm.realm.id
  client_id = data.keycloak_openid_client.realm_management.id
  name      = each.value
}

data "keycloak_openid_client_service_account_user" "rls_lambda_service_account_user" {
  realm_id  = data.keycloak_realm.realm.id
  client_id = keycloak_openid_client.rls_lambda_client.id
}

resource "keycloak_user_roles" "service_account_user_roles" {
  realm_id = data.keycloak_realm.realm.id
  user_id  = data.keycloak_openid_client_service_account_user.rls_lambda_service_account_user.id

  role_ids = concat(
    [for role in data.keycloak_role.rls_lambda_roles : role.id]
  )
}

# Quicksight client

resource "keycloak_saml_client" "Quicksight" {
  realm_id  = data.keycloak_realm.realm.id
  client_id = var.quicksight_client_id
  name      = var.quicksight_client_name

  sign_documents          = true
  sign_assertions         = true
  include_authn_statement = true
  name_id_format          = "transient"
  enabled                 = true
  signature_algorithm     = "RSA_SHA256"
  signature_key_name      = "KEY_ID"
  canonicalization_method = "EXCLUSIVE"

  valid_redirect_uris = [
    "https://signin.aws.amazon.com/saml"
  ]

  base_url = "/auth/realms/${var.kc_realm}/protocol/saml/clients/${var.idp_initiated_sso_url_name}"

  idp_initiated_sso_url_name = var.idp_initiated_sso_url_name

  idp_initiated_sso_relay_state = var.idp_initiated_sso_relay_state

  assertion_consumer_post_url = "https://signin.aws.amazon.com/saml"
  full_scope_allowed          = false
}

# Mappers
resource "keycloak_generic_protocol_mapper" "quicksight_mapper_session_name" {
  realm_id        = data.keycloak_realm.realm.id
  client_id       = keycloak_saml_client.Quicksight.id
  protocol        = "saml"
  name            = "Session Name"
  protocol_mapper = "saml-user-property-mapper"
  config = {
    "user.attribute"       = "email"
    "friendly.name"        = "Session Name"
    "attribute.nameformat" = "Basic"
    "attribute.name"       = "https://aws.amazon.com/SAML/Attributes/RoleSessionName"
  }
}

resource "keycloak_generic_protocol_mapper" "quicksight_mapper_session_role" {
  realm_id        = data.keycloak_realm.realm.id
  client_id       = keycloak_saml_client.Quicksight.id
  protocol        = "saml"
  name            = "Session Role"
  protocol_mapper = "saml-role-list-mapper"
  config = {
    "single"               = true
    "friendly.name"        = "Session Role"
    "attribute.nameformat" = "Basic"
    "attribute.name"       = "https://aws.amazon.com/SAML/Attributes/Role"
  }
}

resource "keycloak_generic_protocol_mapper" "quicksight_mapper_session_duration" {
  realm_id        = data.keycloak_realm.realm.id
  client_id       = keycloak_saml_client.Quicksight.id
  protocol        = "saml"
  name            = "Session Duration"
  protocol_mapper = "saml-hardcode-attribute-mapper"
  config = {
    "attribute.value"      = var.session_duration
    "friendly.name"        = "Session Duration"
    "attribute.nameformat" = "Basic"
    "attribute.name"       = "https://aws.amazon.com/SAML/Attributes/SessionDuration"
  }
}

# Storing rls lambda clinet id and secret values in aws secrets manager
resource "aws_secretsmanager_secret" "client_secret" {
  name                    = "keycloak/client/${keycloak_openid_client.rls_lambda_client.client_id}"
  description             = "Secrets for ${keycloak_openid_client.rls_lambda_client.client_id} Keycloak Client"
  recovery_window_in_days = 0 # Giving it 0 deletes the secret without scheduling it for deletion
}

resource "aws_secretsmanager_secret_version" "rls_lambda_client_secret_version" {
  secret_id = aws_secretsmanager_secret.client_secret.id
  secret_string = jsonencode({
    client_id     = keycloak_openid_client.rls_lambda_client.client_id,
    client_secret = keycloak_openid_client.rls_lambda_client.client_secret
  })
}


# AWS quicksight roles
resource "aws_iam_role" "quicksight_admin" {
  name = "Quicksight-Admin-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.aws_saml_idp_arn
        }
        Action = "sts:AssumeRoleWithSAML"
        Condition = {
          StringEquals = {
            "SAML:aud" = "https://signin.aws.amazon.com/saml"
          }
        }
      },
    ]
  })
}

resource "aws_iam_policy" "quicksight_admin_policy" {
  name   = "Quicksight-Admin-policy"
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "quicksight:CreateAdmin"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "quicksight_admin_policy_attach" {
  role       = aws_iam_role.quicksight_admin.name
  policy_arn = aws_iam_policy.quicksight_admin_policy.arn
}

# Quicksight-Reader-Role with trust to Keycloak SAML provider
resource "aws_iam_role" "quicksight_reader" {
  name = "QuickSight-Reader-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.aws_saml_idp_arn
        }
        Action = "sts:AssumeRoleWithSAML"
        Condition = {
          StringEquals = {
            "SAML:aud" = "https://signin.aws.amazon.com/saml"
          }
        }
      },
    ]
  })
}

resource "aws_iam_policy" "quicksight_reader_policy" {
  name   = "Quicksight-Reader-policy"
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "quicksight:CreateReader"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "quicksight_reader_policy_attach" {
  role       = aws_iam_role.quicksight_reader.name
  policy_arn = aws_iam_policy.quicksight_reader_policy.arn
}


# Attach the above roles created in aws to the quicksight client created in keykloack

resource "keycloak_role" "quicksight_role" {
  for_each    = local.quicksight_roles
  realm_id    = data.keycloak_realm.realm.id
  client_id   = keycloak_saml_client.Quicksight.id
  name        = "${each.value},${var.aws_saml_idp_arn}"
  description = "${each.key} role for QuickSight"
}
# terraform to deploy CFN's