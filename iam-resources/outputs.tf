output "admin_access_role_name" {
  value       = aws_iam_role.admin_access_role.name
  description = "The name of the role users are able to assume to attain admin privileges"
}

output "user_access_role_name" {
  value       = aws_iam_role.user_access_role.name
  description = "The name of the role users are able to assume to attain user privileges"
}
