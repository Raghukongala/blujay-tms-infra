# Terraform variables for the production environment.
# db_password / mongo_password / grafana_admin_password below are
# placeholders -- CI always overrides them with real GitHub Actions
# secrets via -var flags. Never replace these with real credentials.

aws_region   = "ap-south-1"
environment  = "prod"
cluster_name = "blujay-tms-cluster-prod"

# Prod safety: backups on, deletion protection on, HA on.
db_instance_class           = "db.t3.small"
db_multi_az                 = true
db_backup_retention_days    = 7
db_deletion_protection      = true
docdb_instance_class        = "db.t3.medium"
docdb_backup_retention_days = 7
docdb_deletion_protection   = true
redis_ha_enabled            = true

node_instance_type = "t3.medium"
desired_capacity   = 2
min_size           = 2
max_size           = 4

# TODO: replace with your actual office/VPN CIDR(s) and/or CI runner IPs.
# There is no open (0.0.0.0/0) default -- this MUST be set deliberately.
eks_public_access_cidrs = ["203.0.113.0/24"]

db_password            = "REPLACE_WITH_SECRET"
mongo_password         = "REPLACE_WITH_SECRET"
grafana_admin_password = "REPLACE_WITH_SECRET"
certificate_arn        = ""
hosted_zone_id         = ""
