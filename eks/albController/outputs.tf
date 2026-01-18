output "policy_arn" {
  value = aws_iam_policy.alb_controller.arn
}

output "policy_id" {
  value = aws_iam_policy.alb_controller.policy_id
}
