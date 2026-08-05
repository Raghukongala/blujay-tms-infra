locals {
  acm_certificate_arn = var.certificate_arn != "" ? var.certificate_arn : (
    length(aws_acm_certificate.app_cert) > 0 ? aws_acm_certificate.app_cert[0].arn : ""
  )
}

# ── EKS OIDC Provider ───────────────────────────────────────────

data "tls_certificate" "oidc_cert" {
  url = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.oidc_cert.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

# ── ALB Controller IAM ──────────────────────────────────────────

resource "aws_iam_role" "alb_controller" {
  name = "${var.cluster_name}-alb-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:${var.alb_namespace}:${var.alb_service_account_name}"
        }
      }
    }]
  })
}

resource "aws_iam_policy" "alb_controller" {
  name        = "${var.cluster_name}-alb-controller-policy"
  description = "IAM policy for AWS Load Balancer Controller"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "acm:DescribeCertificate",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:CreateSecurityGroup",
        "ec2:CreateTags",
        "ec2:DeleteTags",
        "ec2:DeleteSecurityGroup",
        "ec2:DescribeAccountAttributes",
        "ec2:DescribeAddresses",
        "ec2:DescribeInstances",
        "ec2:DescribeInternetGateways",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeSubnets",
        "ec2:DescribeTags",
        "ec2:DescribeVpcs",
        "ec2:ModifyInstanceAttribute",
        "ec2:ModifyNetworkInterfaceAttribute",
        "ec2:RevokeSecurityGroupIngress",
        "elasticloadbalancing:AddTags",
        "elasticloadbalancing:CreateListener",
        "elasticloadbalancing:CreateLoadBalancer",
        "elasticloadbalancing:CreateRule",
        "elasticloadbalancing:CreateTargetGroup",
        "elasticloadbalancing:DeleteListener",
        "elasticloadbalancing:DeleteLoadBalancer",
        "elasticloadbalancing:DeleteRule",
        "elasticloadbalancing:DeleteTargetGroup",
        "elasticloadbalancing:DeregisterTargets",
        "elasticloadbalancing:DescribeListeners",
        "elasticloadbalancing:DescribeLoadBalancers",
        "elasticloadbalancing:DescribeRules",
        "elasticloadbalancing:DescribeSSLPolicies",
        "elasticloadbalancing:DescribeTags",
        "elasticloadbalancing:DescribeTargetGroups",
        "elasticloadbalancing:DescribeTargetHealth",
        "elasticloadbalancing:ModifyListener",
        "elasticloadbalancing:ModifyLoadBalancerAttributes",
        "elasticloadbalancing:ModifyRule",
        "elasticloadbalancing:ModifyTargetGroup",
        "elasticloadbalancing:ModifyTargetGroupAttributes",
        "elasticloadbalancing:RegisterTargets",
        "elasticloadbalancing:SetIpAddressType",
        "elasticloadbalancing:SetSecurityGroups",
        "elasticloadbalancing:SetSubnets",
        "iam:CreateServiceLinkedRole",
        "iam:GetServerCertificate",
        "iam:ListServerCertificates",
        "wafv2:GetWebACL",
        "wafv2:GetWebACLForResource",
        "wafv2:AssociateWebACL",
        "wafv2:DisassociateWebACL",
        "shield:GetSubscriptionState",
        "shield:DescribeProtection",
        "shield:CreateProtection",
        "shield:DeleteProtection"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "alb_controller_attach" {
  role       = aws_iam_role.alb_controller.name
  policy_arn = aws_iam_policy.alb_controller.arn
}

resource "kubernetes_service_account" "lb_controller" {
  metadata {
    name      = var.alb_service_account_name
    namespace = var.alb_namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.alb_controller.arn
    }
  }
}

resource "helm_release" "aws_lb_controller" {
  name             = "aws-load-balancer-controller"
  repository       = "https://aws.github.io/eks-charts"
  chart            = "aws-load-balancer-controller"
  namespace        = var.alb_namespace
  create_namespace = false

  set {
    name  = "clusterName"
    value = aws_eks_cluster.cluster.name
  }
  set {
    name  = "region"
    value = var.aws_region
  }
  set {
    name  = "vpcId"
    value = aws_vpc.main.id
  }
  set {
    name  = "serviceAccount.create"
    value = "false"
  }
  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.lb_controller.metadata[0].name
  }

  depends_on = [kubernetes_service_account.lb_controller]
}

# ── ACM Certificate (auto-create if no cert ARN provided) ───────

resource "aws_acm_certificate" "app_cert" {
  count             = var.certificate_arn == "" && var.hosted_zone_id != "" ? 1 : 0
  domain_name       = var.domain_name
  validation_method = "DNS"
  subject_alternative_names = ["www.${var.domain_name}"]

  tags = {
    Name        = "${var.cluster_name}-acm-cert"
    Environment = var.environment
  }
}

resource "aws_route53_record" "app_cert_validation" {
  count = var.certificate_arn == "" && var.hosted_zone_id != "" ? 1 : 0

  name    = tolist(aws_acm_certificate.app_cert[0].domain_validation_options)[0].resource_record_name
  type    = tolist(aws_acm_certificate.app_cert[0].domain_validation_options)[0].resource_record_type
  zone_id = var.hosted_zone_id
  records = [tolist(aws_acm_certificate.app_cert[0].domain_validation_options)[0].resource_record_value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "app_cert" {
  count           = var.certificate_arn == "" && var.hosted_zone_id != "" ? 1 : 0
  certificate_arn = aws_acm_certificate.app_cert[0].arn
  validation_record_fqdns = [aws_route53_record.app_cert_validation[0].fqdn]
}

# ── SES Email Identity ──────────────────────────────────────────

resource "aws_ses_email_identity" "notification" {
  count = var.ses_verified_email != "" ? 1 : 0
  email = var.ses_verified_email
}
