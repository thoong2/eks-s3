#!/bin/bash
echo "Downloading file from S3..."
aws s3 cp s3://my-eks-demo-bucket/my-file.txt /tmp/my-file.txt
echo "File downloaded successfully!"
