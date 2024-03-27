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