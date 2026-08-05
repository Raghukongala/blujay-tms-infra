# blujay-tms-infra

Terraform infrastructure for the Blujay Task Management Platform on AWS.

## What this provisions

| Resource | Details |
|---|---|
| VPC | 3 public + 3 private subnets across AZs |
| EKS | `blujay-tms-cluster`, t3.medium nodes |
| ECR | 5 repositories (frontend, user-service, task-service, notification-service, analytics-service) |
| RDS PostgreSQL | `db.t3.micro`, encrypted, private subnet |
| ElastiCache Redis | `cache.t3.micro`, TLS enabled, private subnet |
| DocumentDB | `db.t3.medium`, MongoDB-compatible, encrypted |
| ALB Controller | Helm-installed, IRSA-enabled |
| ACM + Route53 | Auto-created if `hosted_zone_id` is set |
| SES | Email identity if `ses_verified_email` is set |

## Remote State

- S3 bucket: `blujay-tms-tfstate`
- DynamoDB lock table: `blujay-tms-tf-lock`
- Region: `ap-south-1`

## GitHub Secrets Required

| Secret | Description |
|---|---|
| `AWS_ROLE_ARN` | OIDC IAM role ARN |
| `AWS_REGION` | `ap-south-1` |
| `TF_STATE_BUCKET` | `blujay-tms-tfstate` |
| `TF_LOCK_TABLE` | `blujay-tms-tf-lock` |
| `DB_PASSWORD` | RDS PostgreSQL password |
| `MONGO_PASSWORD` | DocumentDB password |
| `SES_FROM_EMAIL` | (optional) SES verified email |
| `ACM_CERTIFICATE_ARN` | (optional) existing ACM cert ARN |
| `HOSTED_ZONE_ID` | (optional) Route53 hosted zone ID |

## Pipeline

- PR → validate + tfsec + checkov + plan (posted as PR comment)
- Merge to main → auto apply
- Manual destroy via workflow_dispatch
