output "config_s3_bucket_arn" {
  description = "The ARN of the S3 bucket AWS Config writes its findings into"
  value       = local.aws_config_s3_bucket_arn
}
