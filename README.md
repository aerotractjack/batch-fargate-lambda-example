# lambda-batch-example
This repo contains terraform scripts to build the following infrastructure:
- S3 buckets for input and output data
- S3 event configuration to trigger Lambda
- Lambda function which triggers Batch job
- ECR repo and Docker config to build and push image
- Batch compute environment, job queue, and job definition
- EFS for Batch
- VPC, 2 public subnets, 2 private subnets, networking config# batch-fargate-lambda-example
