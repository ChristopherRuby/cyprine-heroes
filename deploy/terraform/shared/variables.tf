variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "eu-west-3"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "cyprine-heroes"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}