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

- PR → validate + tfsec + checkov + plan (posted as PR comment)
- Merge to main → auto apply
- Manual destroy via workflow_dispatch
