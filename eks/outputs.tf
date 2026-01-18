output "cluster_id" {
  value = module.eks.cluster_id
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "node_security_group_id" {
  value = module.eks.node_security_group_id
}

output "alb_controller_policy_arn" {
  value = var.generate_alb_controller_iam_policy ? module.alb_controller_policy[0].policy_arn : null
}

output "alb_controller_policy_id" {
  value = var.generate_alb_controller_iam_policy ? module.alb_controller_policy[0].policy_id : null
}

output "oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}

output "oidc_issuer_url" {
  value = module.eks.oidc_provider
}