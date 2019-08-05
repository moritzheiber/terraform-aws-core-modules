output "admin_group_name" {
  value       = aws_iam_group.groups[var.admin_group_name].name
  description = "The name of the admin group"
}

output "user_group_name" {
  value       = aws_iam_group.groups[var.user_group_name].name
  description = "The name of the user group"
}
