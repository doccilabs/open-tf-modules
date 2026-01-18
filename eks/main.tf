module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.37.1"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  # Public access configuration
  cluster_endpoint_public_access       = var.cluster_public_access
  cluster_endpoint_public_access_cidrs = var.cluster_public_access ? ["0.0.0.0/0"] : null

  eks_managed_node_groups = var.eks_managed_node_groups

  node_security_group_additional_rules = merge(
    {
      node_to_node_all = {
        description = "Node-to-node all traffic (required for pod-to-pod, DNS, kube-proxy/service routing)"
        protocol    = "-1"
        from_port   = 0
        to_port     = 0
        type        = "ingress"
        self        = true
      }

      alb_controller_webhook_rule = {
        description                   = "Cluster API to AWS LB Controller webhook"
        protocol                      = "all"
        from_port                     = 9443
        to_port                       = 9443
        type                          = "ingress"
        source_cluster_security_group = true
      }

      allow_kubelet_api = {
        description = "Allow Kubelet API access from VPC"
        protocol    = "TCP"
        from_port   = 10250
        to_port     = 10250
        type        = "ingress"
        cidr_blocks = [var.ipv4_cidr_blocks]
      }

      allow_nodeport_services = {
        description = "Allow NodePort service range"
        protocol    = "TCP"
        from_port   = 30000
        to_port     = 32767
        type        = "ingress"
        cidr_blocks = [var.ipv4_cidr_blocks]
      }

      allow_dns = {
        description = "Allow DNS (TCP/UDP 53)"
        protocol    = "-1"
        from_port   = 53
        to_port     = 53
        type        = "ingress"
        cidr_blocks = [var.ipv4_cidr_blocks]
      }

      control_plane_egress = {
        description                   = "Egress to control plane SG"
        protocol                      = "-1"
        from_port                     = 0
        to_port                       = 0
        type                          = "egress"
        source_cluster_security_group = true
      }
    },
    var.additional_node_sg_rules
  )

  access_entries = merge({}, var.access_entries)

  # terraform 사용자에게 접근 권한 부여
  enable_cluster_creator_admin_permissions = true

  node_security_group_tags = merge(
    var.tags,
    {
      "karpenter.sh/discovery" = var.cluster_name
    }
  )

  tags = merge(var.tags, { Name = var.cluster_name })
}

module "alb_controller_policy" {
  source                     = "./albController"
  count                      = var.generate_alb_controller_iam_policy ? 1 : 0
  alb_controller_policy_name = "${var.cluster_name}-alb-controller-policy"

  depends_on = [module.eks]
}

module "karpenter_controller_polcy" {
  source = "./karpenterController"

  count = var.generate_karpenter_iam_policy ? 1 : 0

  cluster_name = var.cluster_name
  partition    = var.partition
  account_id   = var.account_id
  region       = var.region

  oidc_provider_arn = data.aws_iam_openid_connect_provider.this.arn
  oidc_provider_url = data.aws_eks_cluster.this.identity[0].oidc[0].issuer

  depends_on = [module.eks]
}

module "subnet_tags_for_karpenter" {
  source = "./karpenterSubnetTag"

  count = var.generate_karpenter_iam_policy ? 1 : 0

  subnet_ids   = var.subnet_ids
  cluster_name = var.cluster_name

  depends_on = [module.eks]
}

# External-Secrets-Operator IRSA 설정
module "external_secrets_operator_irsa" {
  source = "./external-secrets-operator-irsa"

  count = var.generate_eso_iam_policy ? 1 : 0

  name              = "external-secrets-operator-iam-role-${var.cluster_name}"
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_issuer_url   = module.eks.oidc_provider

  namespace            = "external-secrets"
  service_account_name = "external-secrets"

  # 가능하면 "*" 대신 필요한 secret ARN만 지정 권장
  secrets_manager_arns = var.secrets_manager_arns

  tags = var.tags

  depends_on = [module.eks]
}