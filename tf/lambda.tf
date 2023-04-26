##########
# LAMBDA #
##########

# Allow lambda to assume this role
resource "aws_iam_role" "iam_for_lambda" {
  name = "stepfn-lambda-assume-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# Attach the step function full access policy to the lambda role
resource "aws_iam_role_policy_attachment" "iam_for_lambda_attach_policy_sfn" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AWSBatchFullAccess"
}

# Create an archive file for our state machine's trigger
data "archive_file" "archive_lambda_trigger" {
    type = "zip"
    output_path = "../batch_trigger/archive.zip"
    source_file = "../batch_trigger/batch_trigger.py"
}

# Create a python fn to act as the trigger to our state machine
resource "aws_lambda_function" "python_lambda_trigger" {
    filename = data.archive_file.archive_lambda_trigger.output_path
    source_code_hash = data.archive_file.archive_lambda_trigger.output_base64sha256
    function_name = "${local.name}-lambda-trigger"
    role = "${aws_iam_role.iam_for_lambda.arn}"
    handler = "batch_trigger.test"
    runtime = "python3.9"
}