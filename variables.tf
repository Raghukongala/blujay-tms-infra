variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "blujay-tms-cluster"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "prod"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "node_instance_type" {
  description = "EKS node instance type"
  type        = string
  default     = "t3.medium"
}

variable "desired_capacity" {
  description = "Desired node count"
  type        = number
  default     = 2
}

variable "min_size" {
  description = "Minimum node count"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum node count"
  type        = number
  default     = 3
}

variable "ecr_repo_prefix" {
  description = "ECR repository name prefix"
  type        = string
  default     = "blujay-tms"
}

variable "domain_name" {
  description = "Primary domain name"
  type        = string
  default     = "blujaytech.com"
}

variable "hosted_zone_id" {
  description = "Route53 hosted zone ID"
  type        = string
  default     = ""
}

variable "certificate_arn" {
  description = "ACM certificate ARN"
  type        = string
  default     = ""
}

variable "ses_verified_email" {
  description = "SES verified sender email"
  type        = string
  default     = ""
}

variable "alb_service_account_name" {
  description = "ALB controller service account name"
  type        = string
  default     = "aws-load-balancer-controller"
}

variable "alb_namespace" {
  description = "Namespace for ALB controller"
  type        = string
  default     = "kube-system"
}

# ── RDS PostgreSQL ──────────────────────────────────────────────
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_username" {
  description = "PostgreSQL master username"
  type        = string
  default     = "taskadmin"
}

variable "db_password" {
  description = "PostgreSQL master password"
  type        = string
  sensitive   = true
}

# ── ElastiCache Redis ───────────────────────────────────────────
variable "redis_node_type" {
  description = "ElastiCache Redis node type"
  type        = string
  default     = "cache.t3.micro"
}

# ── DocumentDB ─────────────────────────────────────────────────
variable "mongo_username" {
  description = "DocumentDB master username"
  type        = string
  default     = "mongoadmin"
}

variable "mongo_password" {
  description = "DocumentDB master password"
  type        = string
  sensitive   = true
}

variable "docdb_instance_class" {
  description = "DocumentDB instance class"
  type        = string
  default     = "db.t3.medium"
}

variable "grafana_admin_password" {
  description = "Grafana admin password (DO NOT set a default in the repo; supply via terraform.tfvars, CI secrets, or AWS Secrets Manager)"
  type        = string
  sensitive   = true
}

# ── Production Hardening Toggles ─────────────────────────────────
# Set explicitly per environment in dev.tfvars / prod.tfvars. No
# environment-based conditionals in resource files -- these are the
# single source of truth so `terraform plan` output is self-explanatory.

variable "db_multi_az" {
  description = "Enable RDS Multi-AZ failover"
  type        = bool
  default     = true
}

variable "db_backup_retention_days" {
  description = "RDS automated backup retention in days (0 disables backups)"
  type        = number
  default     = 7
}

variable "db_deletion_protection" {
  description = "Enable RDS deletion protection"
  type        = bool
  default     = true
}

variable "docdb_backup_retention_days" {
  description = "DocumentDB automated backup retention in days (0 disables backups)"
  type        = number
  default     = 7
}

variable "docdb_deletion_protection" {
  description = "Enable DocumentDB deletion protection"
  type        = bool
  default     = true
}

variable "redis_ha_enabled" {
  description = "Enable Redis multi-node replication with automatic failover"
  type        = bool
  default     = true
}

variable "eks_public_access_cidrs" {
  description = <<-EOT
    CIDR blocks allowed to reach the EKS public API endpoint.
    Required -- there is no open (0.0.0.0/0) default. Populate with your
    office/VPN CIDRs. CI runners also need access; either add GitHub's
    published Actions IP ranges, front CI through a static-IP NAT/proxy,
    or move to self-hosted runners inside the VPC and set this to [].
  EOT
  type        = list(string)

  validation {
    condition     = length(var.eks_public_access_cidrs) > 0
    error_message = "eks_public_access_cidrs must not be empty. Set it explicitly in your .tfvars file -- there is no open default."
  }
}
