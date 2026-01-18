variable "subnet_ids" {
  type        = list(string)
  description = "Subnet ID값"
}

variable "cluster_name" {
  type        = string
  description = "EKS Cluster Name"
}
