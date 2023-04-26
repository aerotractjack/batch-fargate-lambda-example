#############
# BATCH IAM #
#############

# ECS execution role
resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "tf_test_batch_exec_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

# Allow ECS to assume permissions
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# Attach execution policy to role
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

#########################
# EFS STORAGE FOR BATCH #
#########################

# EFS for extra storage for batch
resource "aws_efs_file_system" "efs" {
  creation_token = "${local.name}-efs-creation-token"
  encrypted      = true
  tags = {
    Name = "${local.name}-efs"
  }
}

# Configure access to our EFS
resource "aws_efs_access_point" "efs_ap" {
  file_system_id = aws_efs_file_system.efs.id
  tags = {
    Name = "${local.name}-efs-ap"
  }
}

# Allow VPC and EFS to communicate
resource "aws_efs_mount_target" "vpc_efs_target_private_a" {
  file_system_id = aws_efs_file_system.efs.id
  subnet_id      = aws_subnet.private_a.id
  security_groups = [
    aws_vpc.main.default_security_group_id
  ]
}
resource "aws_efs_mount_target" "vpc_efs_target_private_b" {
  file_system_id = aws_efs_file_system.efs.id
  subnet_id      = aws_subnet.private_b.id
  security_groups = [
    aws_vpc.main.default_security_group_id
  ]
}

#####################
# FARGATE BATCH JOB #
#####################

# Build the compute environment for our batch jobs
resource "aws_batch_compute_environment" "compute_env" {
  compute_environment_name = "${local.name}-compute-env"

  compute_resources {
    max_vcpus = 2
    security_group_ids = [
      aws_vpc.main.default_security_group_id
    ]
    subnets = [
      aws_subnet.public_a.id,
    ]
    type = "FARGATE"
  }
  # service_role = aws_iam_role.ortho_batch_process_role.arn
  # depends_on   = [aws_iam_role.ortho_batch_process_role]
  type         = "MANAGED"
  service_role = "arn:aws:iam::279545598108:role/aws-service-role/batch.amazonaws.com/AWSServiceRoleForBatch"
}

# Construct the job queue
resource "aws_batch_job_queue" "queue" {
  name                 = "${local.name}-batch-job-queue"
  state                = "ENABLED"
  priority             = 1
  compute_environments = ["${aws_batch_compute_environment.compute_env.arn}"]
}

# Define the job
resource "aws_batch_job_definition" "job" {
  name                  = "${local.name}-batch-job-defn"
  type                  = "container"
  platform_capabilities = ["FARGATE"]
  container_properties = jsonencode({
    networkConfiguration = {
      assignPublicIP = "ENABLED"
    }
    executionRoleArn = aws_iam_role.ecs_task_execution_role.arn
    jobRoleArn       = "arn:aws:iam::279545598108:role/batchExecRole"
    image            = aws_ecr_repository.ecr.repository_url
    resourceRequirements = [
      {
        type  = "VCPU"
        value = "1.0"
      },
      {
        type  = "MEMORY"
        value = "2048"
      }
    ]
    mountPoints = [{
      sourceVolume  = "efsVol"
      containerPath = "/mount/efs"
      readOnly      = true
    }]
    volumes = [{
      name = "efsVol"
      efsVolumeConfiguration = {
        filesystemId      = aws_efs_file_system.efs.id
        transitEncryption = "ENABLED"
        authorizationConfig = {
          accessPointId = aws_efs_access_point.efs_ap.id
          iam           = "ENABLED"
        }
      }
    }]
  })
}
