import time
import boto3 
import io
import os

p1, p2 = os.environ.get("p1", "no-p1"), os.environ.get("p2", "no-p2")

tstr = str(int(time.time()))
bucket = "pix4dengine-batch-aerotract-s3-output"
key = f"fargate-test-{tstr}.txt"
msg = f"hello from batch {tstr}: p1={p1}, p2={p2}"

fp = io.BytesIO(bytes(msg, "utf-8"))

s3 = boto3.client("s3")
s3.upload_fileobj(fp, bucket, key)

print(msg)