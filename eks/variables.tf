variable "cluster_name" {
  type        = string
  description = "EKS Cluster Name"
}

variable "cluster_version" {
  type        = string
  description = "EKS Cluster Version"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID값"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet ID값"
}

variable "ipv4_cidr_blocks" {
  type        = string
  description = "IPv4 CIDR Block"
}

variable "additional_node_sg_rules" {
  type        = map(any)
  description = "사용자 정의 노드 SG 추가 규칙 (node_security_group_additional_rules로 병합됨)"
  default     = {}
}

variable "tags" {
  type        = map(string)
  description = "Tags"
}

variable "cluster_public_access" {
  type        = bool
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled"
  default     = false
}

variable "access_entries" {
  type        = any
  description = "Map of access entries to add to the cluster"
  default     = {}
}

variable "generate_alb_controller_iam_policy" {
  description = "If true, generate the ALB controller IAM policy"
  type        = bool
  default     = false
}

// karpenter 생성 관련
variable "generate_karpenter_iam_policy" {
  description = "If true, generate the Karpenter IAM policy"
  type        = bool
  default     = false
}

variable "generate_eso_iam_policy" {
  description = "If true, generate the External Secrets Operator IAM policy"
  type        = bool
  default     = false
}

variable "partition" {
  type    = string
  default = "aws"
}

variable "account_id" {
  type = string
}

variable "region" {
  type = string
}

variable "eks_managed_node_groups" {
  type        = map(any)
  description = "managed node group settings"
  default = {
    default_node_group = {
      desired_size   = 1
      min_size       = 1
      max_size       = 1
      instance_types = ["t3.medium"]
    }
  }
}

variable "secrets_manager_arns" {
  type        = list(string)
  description = "List of Secrets Manager secret ARNs ESO should be able to read"
  default     = []
}