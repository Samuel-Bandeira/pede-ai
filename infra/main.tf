terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  cloud {
    organization = "pedeai"

    workspaces {
      name = "pedeai-infra"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
