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
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 5.57.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cid_dashboards"></a> [cid\_dashboards](#module\_cid\_dashboards) | github.com/aws-samples/aws-cudos-framework-deployment//legacy-terraform/cid-dashboards | 4.3.0 |
| <a name="module_cloud-setup-destination"></a> [cloud-setup-destination](#module\_cloud-setup-destination) | github.com/aws-samples/aws-cudos-framework-deployment//legacy-terraform/cur-setup-destination | 4.3.0 |
| <a name="module_cloud-setup-source"></a> [cloud-setup-source](#module\_cloud-setup-source) | github.com/aws-samples/aws-cudos-framework-deployment//legacy-terraform/cur-setup-source | 4.3.0 |
| <a name="module_rls_lambda"></a> [rls\_lambda](#module\_rls\_lambda) | ./lambda/rls-lambda | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_QuickSightUser"></a> [QuickSightUser](#input\_QuickSightUser) | User name of QuickSight user (as displayed in QuickSight admin panel). The RLS DataSource and DataSet will be owned by this user. | `string` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region to deploy resources | `string` | `"ca-central-1"` | no |
| <a name="input_billing_group_regex"></a> [billing\_group\_regex](#input\_billing\_group\_regex) | Regex to match billing group names in the AWS account. This is used to filter accounts for RLS. | `string` | n/a | yes |
| <a name="input_management_account_id"></a> [management\_account\_id](#input\_management\_account\_id) | Account id of the aws management (or) management account | `string` | n/a | yes |
| <a name="input_operations_account_id"></a> [operations\_account\_id](#input\_operations\_account\_id) | Account id of the aws management (or) management account | `string` | n/a | yes |
| <a name="input_quicksight_reader_group_name"></a> [quicksight\_reader\_group\_name](#input\_quicksight\_reader\_group\_name) | Name of the QuickSight Reader group in IAM Identity Center | `string` | n/a | yes |
| <a name="input_sns_topic_arn"></a> [sns\_topic\_arn](#input\_sns\_topic\_arn) | SNS topic ARN for alarms | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cur_bucket_arn"></a> [cur\_bucket\_arn](#output\_cur\_bucket\_arn) | ARN of the S3 bucket receiving the CUR |
| <a name="output_cur_bucket_name"></a> [cur\_bucket\_name](#output\_cur\_bucket\_name) | Name of the S3 bucket receiving the CUR |
| <a name="output_cur_report_arn"></a> [cur\_report\_arn](#output\_cur\_report\_arn) | ARN of the Cost and Usage Report |
<!-- END_TF_DOCS -->