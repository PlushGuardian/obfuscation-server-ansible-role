#!/usr/bin/env python3
"""
Minimal S3 connectivity test script.
Writes a timestamped test file to the specified S3 bucket.
"""
import boto3
import os
import socket
from datetime import datetime

def write_test_file():
    # Read credentials from environment (set by systemd service)
    aws_access_key = os.environ.get('AWS_ACCESS_KEY_ID')
    aws_secret_key = os.environ.get('AWS_SECRET_ACCESS_KEY')
    aws_region = os.environ.get('AWS_DEFAULT_REGION', 'us-east-1')
    bucket_name = os.environ.get('S3_BUCKET_NAME')
    endpoint_url = os.environ.get('S3_ENDPOINT_URL')

    if not all([aws_access_key, aws_secret_key, bucket_name]):
        print("ERROR: Missing required environment variables")
        return False

    try:
        s3 = boto3.client(
            's3',
            aws_access_key_id=aws_access_key,
            aws_secret_access_key=aws_secret_key,
            region_name=aws_region
        )
        if endpoint_url:
        client_kwargs['endpoint_url'] = endpoint_url
        print(f"Using custom endpoint: {endpoint_url}")

        hostname = socket.gethostname()
        timestamp = datetime.utcnow().strftime('%Y%m%d_%H%M%S')
        key = f"test-files/{hostname}_{timestamp}.txt"
        content = f"Test file from {hostname} at {datetime.utcnow().isoformat()}"

        s3.put_object(
            Bucket=bucket_name,
            Key=key,
            Body=content.encode('utf-8')
        )

        print(f"SUCCESS: File written to s3://{bucket_name}/{key}")
        return True

    except Exception as e:
        print(f"ERROR: Failed to write to S3 - {str(e)}")
        return False

if __name__ == "__main__":
    write_test_file()
