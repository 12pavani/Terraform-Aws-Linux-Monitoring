#!/usr/bin/env bash
# Creates the S3 bucket that stores Terraform remote state.
# Usage: ./bootstrap/create_state_bucket.sh <globally-unique-bucket-name> [region]
set -euo pipefail

BUCKET="${1:?Usage: $0 <globally-unique-bucket-name> [region]}"
REGION="${2:-ap-south-1}"

if [ "$REGION" = "us-east-1" ]; then
  aws s3api create-bucket --bucket "$BUCKET" --region "$REGION"
else
  aws s3api create-bucket --bucket "$BUCKET" --region "$REGION" \
    --create-bucket-configuration "LocationConstraint=$REGION"
fi

aws s3api put-bucket-versioning --bucket "$BUCKET" \
  --versioning-configuration Status=Enabled

aws s3api put-public-access-block --bucket "$BUCKET" \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

aws s3api put-bucket-encryption --bucket "$BUCKET" \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

echo "State bucket ready: $BUCKET ($REGION)"
echo "Next: copy backend.hcl.example to backend.hcl and set bucket = \"$BUCKET\""
