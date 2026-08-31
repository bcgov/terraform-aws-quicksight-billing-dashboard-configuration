terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.62.0"
      # configuration_aliases = [
      #   aws.Management-account
      # ]
    }
  }
}