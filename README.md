# README for AWS QuickSight Dashboards Deployment with Terraform

## Overview
- This repository contains Terraform code for deploying AWS QuickSight dashboards, specifically designed for Cost and Usage Reports (CUR) analysis through CUDOS and Cost Intelligence Dashboards. It leverages an Identity Provider (IdP) for authentication and implements Row-Level Security (RLS) for data access control.

## Prerequisites
- Before deploying the Terraform solution, ensure the following prerequisites are met:
 - Identity Provider Setup: An Identity Provider should be created in AWS for the Keycloak realm. The AWS QuickSight roles configured by this solution have a trust relationship with the IdP, allowing users with assigned roles (Reader and Admin) to authenticate and access the QuickSight dashboards.
 - Cost and Usage Reports Configuration:
    - A S3 bucket will be deployed for CUR storage in the management account.
    - Post-deployment, manually set up CUR to point to this bucket.
    - Transfer any existing CUR data to this new bucket.
- QuickSight Sign-up:
    - Manually sign up for QuickSight in the AWS account where the solution is deployed.
    - Log in to QuickSight and note the username. This username will be used to grant owner rights to the resources deployed by this solution in QuickSight.
## Deployment Process
- Deploy the Terraform configuration, providing all necessary variables.
- Post-deployment, configure the CUR to use the created S3 bucket in the management account.
- Copy existing CUR data to the new bucket. An example script in the example-scripts directory can assist with this process.
- Since the CUR data crawler runs on a schedule, manually trigger it if immediate data visibility is needed post-deployment.
- Log in with the previously noted QuickSight username to access and manage the deployed resources.
## Post-Deployment Configuration
- After copying CUR data to the bucket, ensure to manually run the data crawler if immediate data access is required.
- The RLS Lambda function will synchronize Keycloak users with QuickSight roles, updating access permissions based on user roles and associated accounts. It runs every 30 minutes from 8 AM to 5 PM, Monday through Friday, adhering to QuickSight's data refresh limits.
- Manually run the deployed Account Mapping lambda and the Rls lambda that runs on a schedule for the first time, so that all the existing AWS accounts are mapped and all the users access information is updated
- Quicksight needs to be given appropriate permissions so that it can access the s3 bucket where the cur data is stored and access Amazon Athena, We can do this by heading over to manage quicksight from the quicksight dashboard and using the Security & permissions section
- Email Syncing for Federated Users setting is turned on to allow QuickSight to use a preconfigured email address passed by your identity provider when provisioning new users to this account. This can be done in the Single-ign-on(sso) section of the quicksight settings.
- The workload sso configuration should be deployed so that all the AWS Billing Viewer roles have the Quicksight Reader role attached to it. 
# Accessing the Dashboards
- Once the solution is deployed and configured, users can log in with their designated QuickSight roles (Admin or Reader) to access the relevant dashboards. Data visibility is controlled through RLS, ensuring users only access permitted account data.


## Row-Level Security (RLS) Configuration
The RLS feature in this solution is pivotal for controlling access to the QuickSight dashboards based on user roles and data permissions. It is implemented through a Lambda function that runs periodically to update the RLS settings in QuickSight. Here's how the RLS configuration works in this deployment:

- Lambda Function: A Lambda function is configured to execute every 30 minutes between 8 AM and 5 PM from Monday to Friday. This scheduling aligns with the QuickSight data refresh limits, which is 32 times per 24 hours.

- Role-Based Data Access: The Lambda function is designed to identify users based on their AWS roles. Specifically, it looks for users with the "Billing viewer" role in their respective AWS accounts. Only users with this role are considered for the RLS dataset.

- Data Filtering: Once identified, the Lambda function updates the RLS settings in QuickSight, ensuring that users can only access data related to the AWS accounts where they have the "Billing viewer" role. This ensures that data access is tightly controlled and aligned with user permissions.

- Impact on Dashboard Access: As a result of this RLS configuration, users will see a tailored view of the QuickSight dashboards. They will only have visibility into the cost and usage data of the AWS accounts where they hold the "Billing viewer" role, enhancing security and ensuring data relevance.

- By integrating this role-based access control, the solution ensures that the QuickSight dashboards provide a secure, customized view for each user, aligning with their specific access rights and roles within the AWS environment.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~>5.0 |
| <a name="requirement_keycloak"></a> [keycloak](#requirement\_keycloak) | >= 4.1.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | n/a |
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~>5.0 |
| <a name="provider_aws.master-account"></a> [aws.master-account](#provider\_aws.master-account) | ~>5.0 |
| <a name="provider_keycloak"></a> [keycloak](#provider\_keycloak) | >= 4.1.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cid_dashboards"></a> [cid\_dashboards](#module\_cid\_dashboards) | github.com/aws-samples/aws-cudos-framework-deployment//terraform-modules/cid-dashboards | 0.2.46 |

## Resources

| Name | Type |
|------|------|
| [aws_glue_catalog_table.account_mapping_table](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/glue_catalog_table) | resource |
| [aws_glue_catalog_table.rls_glue_table](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/glue_catalog_table) | resource |
| [aws_iam_policy.athena_and_glue_permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.org_and_s3_permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.quicksight_admin_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.quicksight_reader_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.replication_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.RLSLambdaExecutionRole](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.account_map_lambda_execution_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.account_map_lambda_schedule_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.lambda_schedule_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.quicksight_admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.quicksight_reader](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.replication_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.QuickSightPermissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.S3Permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.SecretsManagerPermissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.invoke_account_map_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.invoke_rls_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.athena_and_glue_permissions_attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.lambda_basic_execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.org_and_s3_permissions_attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.quicksight_admin_policy_attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.quicksight_reader_policy_attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.replication_role_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lambda_function.account_mapping_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_function.rls_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_quicksight_data_set.rls_athena_data_set](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/quicksight_data_set) | resource |
| [aws_quicksight_data_source.quicksight_data_source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/quicksight_data_source) | resource |
| [aws_s3_bucket.cur_export_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.destination_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_policy.destination_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_replication_configuration.replication](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_replication_configuration) | resource |
| [aws_s3_bucket_versioning.cur_export_bucket_versioning](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_bucket_versioning.destination_bucket_versioning](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_scheduler_schedule.account_map_lambda_schedule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/scheduler_schedule) | resource |
| [aws_scheduler_schedule.rls_lambda_schedule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/scheduler_schedule) | resource |
| [aws_secretsmanager_secret.client_secret](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.rls_lambda_client_secret_version](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_ssm_parameter.quicksight_saml_client_id](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [keycloak_generic_protocol_mapper.quicksight_mapper_aws_principaltag](https://registry.terraform.io/providers/mrparkers/keycloak/latest/docs/resources/generic_protocol_mapper) | resource |
| [keycloak_generic_protocol_mapper.quicksight_mapper_session_duration](https://registry.terraform.io/providers/mrparkers/keycloak/latest/docs/resources/generic_protocol_mapper) | resource |
| [keycloak_generic_protocol_mapper.quicksight_mapper_session_name](https://registry.terraform.io/providers/mrparkers/keycloak/latest/docs/resources/generic_protocol_mapper) | resource |
| [keycloak_generic_protocol_mapper.quicksight_mapper_session_role](https://registry.terraform.io/providers/mrparkers/keycloak/latest/docs/resources/generic_protocol_mapper) | resource |
| [keycloak_openid_client.rls_lambda_client](https://registry.terraform.io/providers/mrparkers/keycloak/latest/docs/resources/openid_client) | resource |
| [keycloak_role.quicksight_role](https://registry.terraform.io/providers/mrparkers/keycloak/latest/docs/resources/role) | resource |
| [keycloak_saml_client.Quicksight](https://registry.terraform.io/providers/mrparkers/keycloak/latest/docs/resources/saml_client) | resource |
| [keycloak_user_roles.service_account_user_roles](https://registry.terraform.io/providers/mrparkers/keycloak/latest/docs/resources/user_roles) | resource |
| [archive_file.account_map_lambda_zip](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [archive_file.rls_lambda_zip](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [aws_kms_key.master_account_key_by_alias](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_key) | data source |
| [aws_kms_key.operations_account_key_by_alias](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_key) | data source |
| [keycloak_openid_client.realm_management](https://registry.terraform.io/providers/mrparkers/keycloak/latest/docs/data-sources/openid_client) | data source |
| [keycloak_openid_client_service_account_user.rls_lambda_service_account_user](https://registry.terraform.io/providers/mrparkers/keycloak/latest/docs/data-sources/openid_client_service_account_user) | data source |
| [keycloak_realm.realm](https://registry.terraform.io/providers/mrparkers/keycloak/latest/docs/data-sources/realm) | data source |
| [keycloak_role.rls_lambda_roles](https://registry.terraform.io/providers/mrparkers/keycloak/latest/docs/data-sources/role) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_AWSClientName"></a> [AWSClientName](#input\_AWSClientName) | The name of the AWS client configured in Keycloak | `string` | `"urn:amazon:webservices"` | no |
| <a name="input_AccountMapLambdaScheduleExpression"></a> [AccountMapLambdaScheduleExpression](#input\_AccountMapLambdaScheduleExpression) | The cron schedule for the Account Map Lambda to run. Default is every weekday at 8am. | `string` | `"cron(0 8 ? * MON-FRI *)"` | no |
| <a name="input_AccountMapLambdaTimezone"></a> [AccountMapLambdaTimezone](#input\_AccountMapLambdaTimezone) | The timezone for the Account Map Lambda EventBridge scheduler | `string` | `"Canada/Pacific"` | no |
| <a name="input_CURBucketPath"></a> [CURBucketPath](#input\_CURBucketPath) | S3 path for CUR data.In general, you want to navigate to the folder just before the year partition folders. In this example, the next folder in this path would be year=2024/. Example: s3://<Bucket Name>/<Path> | `string` | n/a | yes |
| <a name="input_ClientIdKey"></a> [ClientIdKey](#input\_ClientIdKey) | The name of the key within the above secret that points to the Client ID | `string` | `"client_id"` | no |
| <a name="input_ClientSecretKey"></a> [ClientSecretKey](#input\_ClientSecretKey) | The name of the key within the above secret that points to the Client Secret | `string` | `"client_secret"` | no |
| <a name="input_KeycloakURL"></a> [KeycloakURL](#input\_KeycloakURL) | The base URL (without http(s)://) of your Keycloak deployment. The Keycloak URL must not contain http(s)://. | `string` | n/a | yes |
| <a name="input_QuickSightUser"></a> [QuickSightUser](#input\_QuickSightUser) | User name of QuickSight user (as displayed in QuickSight admin panel). The RLS DataSource and DataSet will be owned by this user. | `string` | n/a | yes |
| <a name="input_RLSLambdaScheduleExpression"></a> [RLSLambdaScheduleExpression](#input\_RLSLambdaScheduleExpression) | The cron schedule for the RLS Lambda to run. Default is every 30 mins, 8am-5:30pm MON-FRI | `string` | `"cron(0/30 8-17 ? * MON-FRI *)"` | no |
| <a name="input_RLSLambdaTimezone"></a> [RLSLambdaTimezone](#input\_RLSLambdaTimezone) | The timezone for the RLSLambda EventBridge scheduler | `string` | `"Canada/Pacific"` | no |
| <a name="input_aws_master_account_id"></a> [aws\_master\_account\_id](#input\_aws\_master\_account\_id) | Account id of the aws master (or) management account | `string` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region to deploy resources | `string` | `"ca-central-1"` | no |
| <a name="input_aws_saml_idp_arn"></a> [aws\_saml\_idp\_arn](#input\_aws\_saml\_idp\_arn) | Name of the saml identity provider in the aws account | `string` | n/a | yes |
| <a name="input_bcgov_roles_access"></a> [bcgov\_roles\_access](#input\_bcgov\_roles\_access) | Name of the Bc gov role that is needed to get access to the Quicksight dashboards | `string` | n/a | yes |
| <a name="input_cost_and_usage_report_table_name"></a> [cost\_and\_usage\_report\_table\_name](#input\_cost\_and\_usage\_report\_table\_name) | name of the cost and usage report table in athena | `string` | n/a | yes |
| <a name="input_cur_export_bucket_name"></a> [cur\_export\_bucket\_name](#input\_cur\_export\_bucket\_name) | Name of the bucket created in the management account to store exported cur reports | `string` | n/a | yes |
| <a name="input_cur_replication_bucket_name"></a> [cur\_replication\_bucket\_name](#input\_cur\_replication\_bucket\_name) | Name of the bucket where the Cost and Usage reports are replicated. | `string` | n/a | yes |
| <a name="input_iam_replication_policy_name"></a> [iam\_replication\_policy\_name](#input\_iam\_replication\_policy\_name) | Name of the Iam policy created and attached to the iam replication role mentioned above. | `string` | n/a | yes |
| <a name="input_iam_replication_role_name"></a> [iam\_replication\_role\_name](#input\_iam\_replication\_role\_name) | Name of the Iam role used to do the replication. | `string` | n/a | yes |
| <a name="input_idp_initiated_sso_relay_state"></a> [idp\_initiated\_sso\_relay\_state](#input\_idp\_initiated\_sso\_relay\_state) | Url to redirect once the authentication is completed | `string` | n/a | yes |
| <a name="input_idp_initiated_sso_url_name"></a> [idp\_initiated\_sso\_url\_name](#input\_idp\_initiated\_sso\_url\_name) | URL fragment name to reference client when you want to do idp initiated sso | `string` | n/a | yes |
| <a name="input_kc_base_url"></a> [kc\_base\_url](#input\_kc\_base\_url) | Base URL for Keycloak | `any` | n/a | yes |
| <a name="input_kc_realm"></a> [kc\_realm](#input\_kc\_realm) | realm name of the Keycloak | `any` | n/a | yes |
| <a name="input_kc_terraform_auth_client_id"></a> [kc\_terraform\_auth\_client\_id](#input\_kc\_terraform\_auth\_client\_id) | Id of client used to connect to keycloack | `any` | n/a | yes |
| <a name="input_kc_terraform_auth_client_secret"></a> [kc\_terraform\_auth\_client\_secret](#input\_kc\_terraform\_auth\_client\_secret) | secret of client used to connect to keycloack | `any` | n/a | yes |
| <a name="input_master_account_kms_key_alias"></a> [master\_account\_kms\_key\_alias](#input\_master\_account\_kms\_key\_alias) | Alias of the master account kms encryption key | `string` | n/a | yes |
| <a name="input_operations_account_id"></a> [operations\_account\_id](#input\_operations\_account\_id) | Account id of the aws master (or) management account | `string` | n/a | yes |
| <a name="input_operations_account_kms_key_alias"></a> [operations\_account\_kms\_key\_alias](#input\_operations\_account\_kms\_key\_alias) | Alias of the operations account kms encryption key | `string` | n/a | yes |
| <a name="input_quicksight_client_id"></a> [quicksight\_client\_id](#input\_quicksight\_client\_id) | Id of the quicksight client created | `string` | `"Quicksight"` | no |
| <a name="input_quicksight_client_name"></a> [quicksight\_client\_name](#input\_quicksight\_client\_name) | Name of the quicksight client created | `string` | `"Quicksight"` | no |
| <a name="input_rls_lambda_client_id"></a> [rls\_lambda\_client\_id](#input\_rls\_lambda\_client\_id) | Id of the rls lambda client created | `string` | `"rls-lambda"` | no |
| <a name="input_rls_lambda_client_name"></a> [rls\_lambda\_client\_name](#input\_rls\_lambda\_client\_name) | Name of the rls lambda client created | `string` | `"RLS-Lambda-Client"` | no |
| <a name="input_rls_lambda_client_roles"></a> [rls\_lambda\_client\_roles](#input\_rls\_lambda\_client\_roles) | List of Keycloak role names | `list(string)` | <pre>[<br>  "query-clients",<br>  "query-groups",<br>  "query-users",<br>  "view-clients",<br>  "view-users"<br>]</pre> | no |
| <a name="input_session_duration"></a> [session\_duration](#input\_session\_duration) | Session duration length in seconds | `number` | `10800` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cur_replication_bucket_name"></a> [cur\_replication\_bucket\_name](#output\_cur\_replication\_bucket\_name) | Name of the bucket created in the destination account to replicate the CUR data from management account |
| <a name="output_glue_table_name"></a> [glue\_table\_name](#output\_glue\_table\_name) | n/a |
| <a name="output_quicksight_admin_role_arn"></a> [quicksight\_admin\_role\_arn](#output\_quicksight\_admin\_role\_arn) | Arn of the Quicksight Admin role created |
| <a name="output_quicksight_reader_role_arn"></a> [quicksight\_reader\_role\_arn](#output\_quicksight\_reader\_role\_arn) | Arn of the Quicksight reader role created |
<!-- END_TF_DOCS -->