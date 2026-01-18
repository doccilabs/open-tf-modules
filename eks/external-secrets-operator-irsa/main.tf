locals {
  oidc_issuer_hostpath = replace(var.oidc_issuer_url, "https://", "")
  sa_sub               = "system:serviceaccount:${var.namespace}:${var.service_account_name}"
}

resource "aws_iam_role" "this" {
  name = var.name
  tags = var.tags

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
          "${local.oidc_issuer_hostpath}:sub" = local.sa_sub,
          "${local.oidc_issuer_hostpath}:aud" = "sts.amazonaws.com"
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

resource "aws_iam_policy" "this" {
  name = "${var.name}-policy"
  tags = var.tags

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "SecretsManagerRead",
        Effect = "Allow",
        Action = [
          "secretsmanager:ListSecrets",
          "secretsmanager:BatchGetSecretValue",
          "secretsmanager:GetResourcePolicy",
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds"
        ],
        Resource = var.secrets_manager_arns
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}