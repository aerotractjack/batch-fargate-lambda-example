##############
# S3 BUCKETS #
##############

resource "aws_s3_bucket" "input_bucket" {
    bucket = "${local.name}-s3-input"
    force_destroy = true
}

# Create a lambda function trigger event when an object is created in the input bucket
resource "aws_s3_bucket_notification" "obj_created_notif" {
    bucket      = aws_s3_bucket.input_bucket.id
    lambda_function {
        lambda_function_arn = "${aws_lambda_function.python_lambda_trigger.arn}"
        events              = ["s3:ObjectCreated:*"]
    }   
    depends_on = [aws_lambda_function.python_lambda_trigger]
}

# Allow our input bucket to invoke our lambda trigger function
resource "aws_lambda_permission" "s3_invoke_lambda_trigger" {
statement_id  = "AllowS3Invoke"
action        = "lambda:InvokeFunction"
function_name = "${aws_lambda_function.python_lambda_trigger.function_name}"
principal = "s3.amazonaws.com"
source_arn = "arn:aws:s3:::${aws_s3_bucket.input_bucket.id}"
}

resource "aws_s3_bucket" "output_bucket" {
    bucket = "${local.name}-s3-output"
    force_destroy = true
}