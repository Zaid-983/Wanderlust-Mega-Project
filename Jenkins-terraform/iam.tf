# ╔══════════════════════════════════════════════════════════════╗
# ║           iam.tf — IAM User for EKS Cluster Creation        ║
# ║                                                             ║
# ║  Creates:                                                   ║
# ║  1. IAM User         → eks-admin                            ║
# ║  2. IAM Policy       → full EKS + required permissions      ║
# ║  3. Policy Attachment → attaches policy to user             ║
# ║  4. Access Keys      → programmatic access for eksctl       ║
# ╚══════════════════════════════════════════════════════════════╝

# ──────────────────────────────────────────────────────────────
# RESOURCE 1: IAM User
# This user will be used by eksctl to create EKS cluster
# ──────────────────────────────────────────────────────────────
resource "aws_iam_user" "eks_admin" {
  name = "eks-admin"

  tags = {
    Name      = "EKS Admin User"
    Project   = "wanderlust"
    ManagedBy = "terraform"
  }
}

# ──────────────────────────────────────────────────────────────
# RESOURCE 2: IAM Policy
# All permissions required to create and manage EKS cluster
#
# WHY THESE PERMISSIONS?
#   eks:*          → create/manage EKS cluster and node groups
#   ec2:*          → create VPC, subnets, SGs for EKS nodes
#   iam:*          → create roles for EKS service accounts
#   cloudformation → eksctl uses CF stacks under the hood
#   autoscaling    → manages node group auto scaling
#   elasticloadbalancing → creates LB for services
#   ssm:GetParameter → reads AMI IDs for node groups
# ──────────────────────────────────────────────────────────────
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

# ──────────────────────────────────────────────────────────────
# RESOURCE 4: Access Keys
# Generates Access Key ID + Secret Access Key
# Used by eksctl / AWS CLI on Jenkins Agent
#
# ⚠️  IMPORTANT:
#   Secret key is stored in Terraform state (S3 bucket)
#   Never print it in logs or commit to git
#   Rotate regularly for security
# ──────────────────────────────────────────────────────────────
resource "aws_iam_access_key" "eks_admin_key" {
  user = aws_iam_user.eks_admin.name
}

# ──────────────────────────────────────────────────────────────
# Save credentials to local file (for use on Jenkins Agent)
# File is created in your Jenkins-terraform/ folder
# ADD eks-credentials.txt TO .gitignore IMMEDIATELY
# ──────────────────────────────────────────────────────────────
resource "local_sensitive_file" "eks_credentials" {
  content = <<-EOT
    [eks-admin]
    aws_access_key_id     = ${aws_iam_access_key.eks_admin_key.id}
    aws_secret_access_key = ${aws_iam_access_key.eks_admin_key.secret}
    region                = us-east-1
  EOT

  filename        = "${path.module}/eks-credentials.txt"
  file_permission = "0400"
}

