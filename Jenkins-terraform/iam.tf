
# RESOURCE 1: IAM User

resource "aws_iam_user" "eks_admin" {
  name = "eks-admin"

  tags = {
    Name      = "EKS Admin User"
    Project   = "wanderlust"
    ManagedBy = "terraform"
  }
}

# RESOURCE 2: IAM Policy

resource "aws_iam_policy" "eks_admin_policy" {
  name        = "eks-admin-policy"
  description = "Full permissions for EKS cluster creation and management"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # EKS Full Access
      {
        Sid    = "EKSFullAccess"
        Effect = "Allow"
        Action = [
          "eks:*"
        ]
        Resource = "*"
      },
      {
        "Sid": "ServiceLinkedRole",
        "Effect": "Allow",
        "Action": [
          "iam:CreateServiceLinkedRole",
          "iam:DeleteServiceLinkedRole",
          "iam:GetServiceLinkedRoleDeletionStatus"
          ],
        "Resource": "arn:aws:iam::*:role/aws-service-role/eks.amazonaws.com/*"

      },
    
      # EC2 Access (required for VPC, subnets, SGs, instances)
      {
        Sid    = "EC2FullAccess"
        Effect = "Allow"
        Action = [
          "ec2:*"
        ]
        Resource = "*"
      },
      # IAM Access (required for node group roles and service accounts)
      {
        Sid    = "IAMFullAccess"
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListRoles",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:PassRole",
          "iam:CreateInstanceProfile",
          "iam:DeleteInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:GetInstanceProfile",
          "iam:ListInstanceProfiles",
          "iam:ListInstanceProfilesForRole",
          "iam:CreateOpenIDConnectProvider",
          "iam:DeleteOpenIDConnectProvider",
          "iam:GetOpenIDConnectProvider",
          "iam:ListOpenIDConnectProviders",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:TagInstanceProfile"
        ]
        Resource = "*"
      },
      # CloudFormation (eksctl creates CF stacks internally)
      {
        Sid    = "CloudFormationFullAccess"
        Effect = "Allow"
        Action = [
          "cloudformation:*"
        ]
        Resource = "*"
      },
      # Auto Scaling (manages EKS node groups)
      {
        Sid    = "AutoScalingFullAccess"
        Effect = "Allow"
        Action = [
          "autoscaling:*"
        ]
        Resource = "*"
      },
      # Elastic Load Balancing (for K8s services of type LoadBalancer)
      {
        Sid    = "ELBFullAccess"
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:*"
        ]
        Resource = "*"
      },
      # SSM Parameter Store (eksctl reads AMI IDs from SSM)
      {
        Sid    = "SSMReadAccess"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = "*"
      },
      # KMS (optional - for encrypted EKS secrets)
      {
        Sid    = "KMSAccess"
        Effect = "Allow"
        Action = [
          "kms:CreateKey",
          "kms:DescribeKey",
          "kms:CreateAlias",
          "kms:ListAliases"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name      = "EKS Admin Policy"
    Project   = "wanderlust"
    ManagedBy = "terraform"
  }
}

# ──────────────────────────────────────────────────────────────
# RESOURCE 3: Attach Policy to User
# ──────────────────────────────────────────────────────────────
resource "aws_iam_user_policy_attachment" "eks_admin_policy_attachment" {
  user       = aws_iam_user.eks_admin.name
  policy_arn = aws_iam_policy.eks_admin_policy.arn
}


# RESOURCE 4: Access Keys

resource "aws_iam_access_key" "eks_admin_key" {
  user = aws_iam_user.eks_admin.name
}

# ──────────────────────────────────────────────────────────────
# Save credentials to local file (for use on Jenkins Agent)

resource "local_sensitive_file" "eks_credentials" {
  content = <<-EOT
    [eks-admin]
    aws_access_key_id     = ${aws_iam_access_key.eks_admin_key.id}
    aws_secret_access_key = ${aws_iam_access_key.eks_admin_key.secret}
    region                = us-east-2
  EOT

  filename        = "${path.module}/eks-credentials.txt"
  file_permission = "0400"
}

