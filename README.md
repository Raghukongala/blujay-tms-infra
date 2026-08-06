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
| `GRAFANA_ADMIN_PASSWORD` | Grafana admin login (required — no default in code) |
| `SES_FROM_EMAIL` | (optional) SES verified email |
| `ACM_CERTIFICATE_ARN` | (optional) existing ACM cert ARN |
| `HOSTED_ZONE_ID` | (optional) Route53 hosted zone ID |

## GitHub Actions Variables Required

Settings → Secrets and variables → Actions → **Variables** tab (not Secrets — this isn't sensitive):

| Variable | Description |
|---|---|
| `TF_VERSION` | Terraform version, e.g. `1.12.2`. Read by both `terraform-pr.yml` and `terraform-deploy.yml` so plan and apply can never run on different Terraform versions. |

## Production Environment Protection (required)

`terraform-deploy.yml`'s `apply` job runs under the `production` GitHub Environment. For it to actually gate deploys:

1. Settings → Environments → create (or edit) an environment named `production`.
2. Enable **Required reviewers** and add at least one person other than the PR author.
3. Under **Deployment branches and tags**, restrict to `main` only.

Without this, the workflow-level branch guard is your only protection — the environment gate is what makes an actual human approve the exact reviewed plan before it touches prod.

## Provider Lock File

`.terraform.lock.hcl` is currently gitignored, meaning every CI run can pick up a new provider version within the `~> 5.0` AWS provider constraint and produce an unexpected plan diff. Generate and commit it deliberately:

```bash
terraform init -upgrade
git add -f .terraform.lock.hcl   # remove .terraform.lock.hcl from .gitignore first
```

Bump it via an explicit PR (`terraform init -upgrade`) when you want a new provider version, not implicitly on every CI run. This repo doesn't include a generated lock file yet — that step needs to run somewhere with real network access to the Terraform registry.

## Two IAM Policy Files

`inline-policy.json` and `github-actions-deploy-role-policy.json` currently contain identical least-privilege permissions for the GitHub Actions deploy role. Having both invites drift (they diverged once already — a wildcard KMS resource crept into one but not the other). Confirm which one is actually attached to the IAM role in AWS and delete the other, or keep both in sync deliberately.

## Required AWS Role Permissions

The IAM role assumed by GitHub Actions should use least privilege. The `inline-policy.json` file now contains a baseline policy with explicit service actions required to provision this stack.

Minimum required permissions include:

- EKS: `eks:CreateCluster`, `eks:DeleteCluster`, `eks:DescribeCluster`, `eks:DescribeClusters`, `eks:ListClusters`, `eks:CreateNodegroup`, `eks:DeleteNodegroup`, `eks:DescribeNodegroup`, `eks:DescribeNodegroups`, `eks:ListNodegroups`, `eks:TagResource`, `eks:UntagResource`
- EC2: `ec2:CreateVpc`, `ec2:DeleteVpc`, `ec2:DescribeVpcs`, `ec2:CreateSubnet`, `ec2:DeleteSubnet`, `ec2:DescribeSubnets`, `ec2:ModifySubnetAttribute`, `ec2:CreateInternetGateway`, `ec2:AttachInternetGateway`, `ec2:CreateNatGateway`, `ec2:CreateRouteTable`, `ec2:CreateRoute`, `ec2:AssociateRouteTable`, `ec2:CreateSecurityGroup`, `ec2:AuthorizeSecurityGroupIngress`, `ec2:RevokeSecurityGroupIngress`, `ec2:CreateLaunchTemplate`, `ec2:CreateLaunchTemplateVersion`, `ec2:CreateTags`, `ec2:DeleteTags`, `ec2:DescribeTags`
- IAM: `iam:CreateRole`, `iam:DeleteRole`, `iam:GetRole`, `iam:ListRoles`, `iam:UpdateRole`, `iam:PassRole`, `iam:AttachRolePolicy`, `iam:DetachRolePolicy`, `iam:CreateOpenIDConnectProvider`, `iam:DeleteOpenIDConnectProvider`, `iam:GetOpenIDConnectProvider`, `iam:UpdateOpenIDConnectProviderThumbprint`, `iam:CreateServiceLinkedRole`
- RDS: `rds:CreateDBSubnetGroup`, `rds:DeleteDBSubnetGroup`, `rds:ModifyDBSubnetGroup`, `rds:DescribeDBSubnetGroups`, `rds:CreateDBInstance`, `rds:DeleteDBInstance`, `rds:ModifyDBInstance`, `rds:DescribeDBInstances`, `rds:AddTagsToResource`, `rds:RemoveTagsFromResource`, `rds:ListTagsForResource`
- DocumentDB: `docdb:CreateDBCluster`, `docdb:DeleteDBCluster`, `docdb:ModifyDBCluster`, `docdb:DescribeDBClusters`, `docdb:CreateDBClusterInstance`, `docdb:DeleteDBClusterInstance`, `docdb:ModifyDBClusterInstance`, `docdb:DescribeDBInstances`, `docdb:CreateDBSubnetGroup`, `docdb:DeleteDBSubnetGroup`, `docdb:ModifyDBSubnetGroup`, `docdb:DescribeDBSubnetGroups`, `docdb:TagResource`, `docdb:UntagResource`
- ElastiCache: `elasticache:CreateCacheSubnetGroup`, `elasticache:DeleteCacheSubnetGroup`, `elasticache:ModifyCacheSubnetGroup`, `elasticache:DescribeCacheSubnetGroups`, `elasticache:CreateReplicationGroup`, `elasticache:DeleteReplicationGroup`, `elasticache:ModifyReplicationGroup`, `elasticache:DescribeReplicationGroups`, `elasticache:AddTagsToResource`, `elasticache:RemoveTagsFromResource`, `elasticache:ListTagsForResource`
- ECR: `ecr:CreateRepository`, `ecr:DeleteRepository`, `ecr:DescribeRepositories`, `ecr:PutImageScanningConfiguration`, `ecr:PutLifecyclePolicy`, `ecr:TagResource`, `ecr:UntagResource`
- KMS: `kms:CreateKey`, `kms:CreateAlias`, `kms:DescribeKey`, `kms:PutKeyPolicy`, `kms:TagResource`, `kms:EnableKeyRotation`, `kms:ListAliases`
- Secrets Manager: `secretsmanager:CreateSecret`, `secretsmanager:PutSecretValue`, `secretsmanager:GetSecretValue`, `secretsmanager:DescribeSecret`, `secretsmanager:DeleteSecret`, `secretsmanager:TagResource`
- Logs / CloudWatch: `logs:CreateLogGroup`, `logs:DeleteLogGroup`, `logs:DescribeLogGroups`, `logs:PutRetentionPolicy`, `cloudwatch:PutMetricAlarm`, `cloudwatch:DeleteAlarms`, `cloudwatch:DescribeAlarms`, `cloudwatch:DescribeAlarmsForMetric`
- WAF: `wafv2:CreateWebACL`, `wafv2:DeleteWebACL`, `wafv2:UpdateWebACL`, `wafv2:GetWebACL`, `wafv2:ListWebACLs`, `wafv2:PutLoggingConfiguration`, `wafv2:DeleteLoggingConfiguration`
- SNS: `sns:CreateTopic`, `sns:DeleteTopic`, `sns:GetTopicAttributes`, `sns:SetTopicAttributes`, `sns:TagResource`, `sns:UntagResource`
- ACM: `acm:RequestCertificate`, `acm:DescribeCertificate`, `acm:DeleteCertificate`, `acm:AddTagsToCertificate`, `acm:ListCertificates`
- Route53: `route53:ChangeResourceRecordSets`, `route53:GetChange`, `route53:ListHostedZones`, `route53:ListHostedZonesByName`, `route53:ListResourceRecordSets`
- SES (optional): `ses:VerifyEmailIdentity`, `ses:GetIdentityVerificationAttributes`, `ses:ListIdentities`
- S3: `s3:GetObject`, `s3:PutObject`, `s3:DeleteObject`, `s3:ListBucket`, `s3:GetBucketVersioning`, `s3:GetBucketAcl`, `s3:GetBucketLocation`
- DynamoDB: `dynamodb:GetItem`, `dynamodb:PutItem`, `dynamodb:DeleteItem`, `dynamodb:DescribeTable`
- STS: `sts:GetCallerIdentity`

> Note: The repository now attaches the AWS-managed `AWSLoadBalancerControllerIAMPolicy` to the ALB controller service account role, which avoids requiring `iam:CreatePolicy` in the CI deployment role.

## Pipeline

**`terraform-pr.yml`** — on every PR to `main`:
1. `validate` job: `fmt`, `validate`, TFLint, Checkov (blocking on HIGH/CRITICAL), Trivy config scan (blocking on HIGH/CRITICAL).
2. `plan` job: plans **both** `dev` and `prod` state, using each environment's `.tfvars`, and posts both as separate PR comments — so reviewers see the real prod diff before merge, not just dev's.

**`terraform-deploy.yml`** — on push to `main` (or manual `workflow_dispatch`, branch-guarded to `main` only):
1. `guard` job: hard-fails if not running on `main`.
2. `plan` job: plans against `blujay/prod/terraform.tfstate`, uploads the plan file as a build artifact. If there are no changes, the pipeline stops here — no empty apply runs.
3. `apply` job: gated by the `production` GitHub Environment (required reviewer + branch restriction, see below). Downloads the **exact plan artifact** from step 2 and applies it with `terraform apply tfplan` — what gets approved is guaranteed to be what executes, with no chance of drift between review and apply.

Both workflows are pinned to the same Terraform version via the `TF_VERSION` repository variable — never hardcode a version directly in either workflow file again.
