# Example Terraform variables for production

aws_region   = "ap-south-1"
environment  = "prod"
cluster_name = "blujay-tms-cluster-prod"

# DO NOT commit real secrets. Provide these via CI (GitHub secrets) or AWS Secrets Manager.
db_password     = "REPLACE_WITH_SECRET"
mongo_password  = "REPLACE_WITH_SECRET"
certificate_arn = ""
hosted_zone_id  = ""