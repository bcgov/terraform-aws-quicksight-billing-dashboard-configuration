terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.57.0"
      # configuration_aliases = [
      #   aws.Management-account
      # ]
    }
  }
}