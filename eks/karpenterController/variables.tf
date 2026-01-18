variable "cluster_name" {
  type        = string
  description = "EKS Cluster name"
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

variable "oidc_provider_arn" {
  type = string
}

variable "oidc_provider_url" {
  type = string
}
