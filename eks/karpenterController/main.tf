resource "aws_iam_role" "karpenter_controller" {
  name = "${var.cluster_name}-karpenter-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Federated = var.oidc_provider_arn
      },
      Action = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        StringEquals = {
          "${replace(var.oidc_provider_url, "https://", "")}:sub" = "system:serviceaccount:kube-system:karpenter"
        }
      }
    }]
  })

  lifecycle {
    ignore_changes = [
      assume_role_policy
    ]
  }
}

resource "aws_iam_policy" "karpenter_controller" {
  name        = "${var.cluster_name}-KarpenterControllerPolicy"
  description = "IAM Policy for Karpenter Controller"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "Karpenter",
        Effect = "Allow",
        Action = [
          "ssm:GetParameter",
          "ec2:DescribeImages",
          "ec2:RunInstances",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DescribeAvailabilityZones",
          "ec2:DeleteLaunchTemplate",
          "ec2:CreateTags",
          "ec2:CreateLaunchTemplate",
          "ec2:CreateFleet",
          "ec2:DescribeSpotPriceHistory",
          "pricing:GetProducts",
          "iam:GetInstanceProfile",
          "iam:CreateInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:DeleteInstanceProfile",
          "iam:TagInstanceProfile"
        ],
        Resource = "*"
      },
      {
        Sid    = "AllowCreateServiceLinkedRoleForEC2Spot",
        Effect = "Allow",
        Action = "iam:CreateServiceLinkedRole",
        Resource = "*",
        Condition = {
          StringEqualsIfExists = {
            "iam:AWSServiceName" = "spot.amazonaws.com"
          }
        }
      },
      {
        Sid      = "ConditionalEC2Termination",
        Effect   = "Allow",
        Action   = "ec2:TerminateInstances",
        Resource = "*",
        Condition = {
          StringLike = {
            "ec2:ResourceTag/karpenter.sh/provisioner-name" = "*"
          }
        }
      },
      {
        Sid      = "PassNodeIAMRole",
        Effect   = "Allow",
        Action   = "iam:PassRole",
        Resource = "arn:${var.partition}:iam::${var.account_id}:role/KarpenterNodeRole-${var.cluster_name}"
      },
      {
        Sid      = "EKSClusterEndpointLookup",
        Effect   = "Allow",
        Action   = "eks:DescribeCluster",
        Resource = "arn:${var.partition}:eks:${var.region}:${var.account_id}:cluster/${var.cluster_name}"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "karpenter_controller_attach" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = aws_iam_policy.karpenter_controller.arn
}

resource "aws_iam_role" "karpenter_node" {
  name = "KarpenterNodeRole-${var.cluster_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = [
        "sts:AssumeRole"
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "karpenter_node_worker_attach" {
  role       = aws_iam_role.karpenter_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "karpenter_node_cni_attach" {
  role       = aws_iam_role.karpenter_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "karpenter_node_ecr_attach" {
  role       = aws_iam_role.karpenter_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}