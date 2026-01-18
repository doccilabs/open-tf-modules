variable "name" {
  type = string
}

variable "oidc_provider_arn" {
  type = string
}

variable "oidc_issuer_url" {
  type        = string
  description = "EKS OIDC issuer URL with https://"
}

variable "namespace" {
  type    = string
  default = "external-secrets"
}

variable "service_account_name" {
  type    = string
  default = "external-secrets"
}

variable "secrets_manager_arns" {
  type        = list(string)
  description = "List of Secrets Manager secret ARNs ESO should be able to read"
  default     = ["*"]
}

variable "tags" {
  type    = map(string)
  default = {}
}