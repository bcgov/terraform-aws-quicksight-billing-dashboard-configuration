terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~>4.0"
    }
    keycloak = {
      source  = "mrparkers/keycloak"
      version = ">= 4.1.0"
    }
  }
}