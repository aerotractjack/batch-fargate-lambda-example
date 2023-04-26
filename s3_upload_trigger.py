import time
import boto3 
import io

tstr = str(int(time.time()))
bucket = "pix4dengine-batch-aerotract-s3-input"
key = f"fargate-test-{tstr}.txt"
msg = f"hello from local {tstr}"

fp = io.BytesIO(bytes(msg, "utf-8"))

s3 = boto3.client("s3")
s3.upload_fileobj(fp, bucket, key)

print(msg)