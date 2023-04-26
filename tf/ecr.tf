#######
# ECR #
#######

# Give Docker permission to pusher Docker Images to AWS.
data "aws_caller_identity" "this" {}
data "aws_ecr_authorization_token" "this" {}
data "aws_region" "this" {}
locals {
  ecr_address = format("%v.dkr.ecr.%v.amazonaws.com",
    data.aws_caller_identity.this.account_id,
  data.aws_region.this.name)
}
provider "docker" {
  registry_auth {
    address  = local.ecr_address
    password = data.aws_ecr_authorization_token.this.password
    username = data.aws_ecr_authorization_token.this.user_name
  }
}

# ECR repo for our image
resource "aws_ecr_repository" "ecr" {
  name         = local.example
  force_delete = true
}

# Build image locally and tag as :latest
resource "docker_image" "this" {
  name = format("%v:latest", aws_ecr_repository.ecr.repository_url)
  build { context = "../batch_service" } # Path to our Dockerfile
}

# Push image to our ECR
resource "docker_registry_image" "this" {
  keep_remotely = true # Do not delete old images when a new image is pushed
  name          = resource.docker_image.this.name
}
