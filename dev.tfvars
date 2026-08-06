# Terraform variables for the dev environment.
# db_password / mongo_password / grafana_admin_password below are
# placeholders -- CI always overrides them with real GitHub Actions
# secrets via -var flags. Never replace these with real credentials.

aws_region   = "ap-south-1"
environment  = "dev"
cluster_name = "blujay-tms-cluster-dev"

# Cheaper/relaxed settings acceptable for a non-prod environment.
db_instance_class           = "db.t3.micro"
db_multi_az                 = false
db_backup_retention_days    = 1
db_deletion_protection      = false
docdb_instance_class        = "db.t3.medium"
docdb_backup_retention_days = 1
docdb_deletion_protection   = false
redis_ha_enabled            = false

node_instance_type = "t3.medium"
desired_capacity   = 1
min_size           = 1
max_size           = 2

# TODO: replace with your actual office/VPN CIDR(s) and/or CI runner IPs.
eks_public_access_cidrs = ["203.0.113.0/24"]

db_password            = "REPLACE_WITH_SECRET"
mongo_password         = "REPLACE_WITH_SECRET"
grafana_admin_password = "REPLACE_WITH_SECRET"
certificate_arn        = ""
hosted_zone_id         = ""
