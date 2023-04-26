terraform {
  required_version = "~> 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.56"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region                   = "us-west-1"
  shared_config_files      = ["/home/aerotract/.aws/config"]
  shared_credentials_files = ["/home/aerotract/.aws/credentials"]
  profile                  = "default"
}

locals {
  name           = "pix4dengine-batch-aerotract"
  container_name = "pix4dengine-batch-aerotract"
  container_port = 80
  example        = "pix4dengine-batch-aerotract"
}
