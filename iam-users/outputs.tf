output "admin_group_name" {
  value       = aws_iam_group.admins.name
  description = "The name of the admin group"
}

output "user_group_name" {
  value       = aws_iam_group.users.name
  description = "The name of the user group"
}
