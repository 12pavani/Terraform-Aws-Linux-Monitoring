# Remote state in S3. Bucket/key/region are supplied at init time:
#   terraform init -backend-config=backend.hcl
# To use local state instead, delete this file.
terraform {
  backend "s3" {}
}
