output "vpc_id" {
  value       = aws_vpc.core.id
  description = "The ID of the created VPC"
}

output "public_subnet_ids" {
  value = aws_subnet.public_subnet[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private_subnet[*].id
}
