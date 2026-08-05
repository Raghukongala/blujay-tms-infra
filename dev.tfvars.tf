# Example Terraform variables for development

aws_region = "ap-south-1"
environment = "dev"
cluster_name = "blujay-tms-cluster-dev"

# Do NOT store real secrets in this file. Use GitHub secrets or AWS Secrets Manager in CI.
db_password = "REPLACE_WITH_SECRET"
mongo_password = "REPLACE_WITH_SECRET"
certificate_arn = ""
hosted_zone_id = ""