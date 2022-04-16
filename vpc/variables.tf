variable "tags" {
  type        = map(string)
  description = "A map of tags to apply to all VPC resources"
  default     = {}
}

variable "vpc_name" {
  type        = string
  description = "The name of the VPC"
  default     = "core_vpc"
}

variable "vpc_cidr_range" {
  type        = string
  description = "The IP address space to use for the VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnet_size" {
  type        = number
  description = "The size of the public subnet (default: 1022 usable addresses)"
  default     = 6
}

variable "private_subnet_size" {
  type        = number
  description = "The size of the private subnet (default: 1022 usable addresses)"
  default     = 6
}

variable "private_subnet_offset" {
  type        = number
  description = "The amount of IP space between the public and the private subnet"
  default     = 2
}

variable "public_subnet_prefix" {
  type        = string
  description = "The prefix to attach to the name of the public subnets"
  default     = ""
}

variable "private_subnet_prefix" {
  type        = string
  description = "The prefix to attach to the name of the private subnets"
  default     = ""
}

variable "enable_dns_support" {
  type        = bool
  description = "Whether or not to enable VPC DNS support"
  default     = true
}

variable "enable_dns_hostnames" {
  type        = bool
  description = "Whether or not to enable VPC DNS hostname support"
  default     = true
}
