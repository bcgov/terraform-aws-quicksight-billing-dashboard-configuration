terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.62.0"
      configuration_aliases = [
        aws.Management,
        aws.Operations,
        aws.useast1-Management,
        aws.useast1-operations
      ]
    }
  }
}
