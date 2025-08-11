terraform {
  # Backend configuration - uncomment and configure for remote state
  # backend "s3" {
  #   bucket = "cyprine-heroes-terraform-state-prod"
  #   key    = "prod/terraform.tfstate"
  #   region = "eu-west-3"
  # }

  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Load shared configuration
module "shared" {
  source = "../../shared"
  
  aws_region   = var.aws_region
  project_name = var.project_name
  environment  = var.environment
}

# Deploy EC2 infrastructure
module "cyprine_ec2" {
  source = "../../modules/ec2"

  # Basic configuration
  project_name  = var.project_name
  environment   = var.environment
  instance_type = var.instance_type
  volume_size   = var.volume_size
  key_name      = var.key_name
  
  # Network security
  allowed_ssh_cidrs = var.allowed_ssh_cidrs
  
  # Application configuration
  database_url   = var.database_url
  secret_key     = var.secret_key
  admin_password = var.admin_password
  cors_origins   = var.cors_origins
  github_repo    = var.github_repo
}

# Provider configuration
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Application = "cyprine-heroes"
      Repository  = var.github_repo
    }
  }
}