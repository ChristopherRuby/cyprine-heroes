data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Default VPC and subnet (for simplicity)
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_instance" "cyprine_heroes" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.cyprine_sg.id]
  subnet_id              = tolist(data.aws_subnets.default.ids)[0]

  root_block_device {
    volume_type = "gp3"
    volume_size = var.volume_size
    encrypted   = true
    
    tags = {
      Name = "${var.project_name}-root-volume"
    }
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    database_url    = var.database_url
    secret_key      = var.secret_key
    admin_password  = var.admin_password
    cors_origins    = var.cors_origins
    github_repo     = var.github_repo
    project_name    = var.project_name
    domain_name     = var.domain_name
  }))

  tags = {
    Name = "${var.project_name}-${var.environment}"
    Type = "application-server"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Elastic IP for the instance
resource "aws_eip" "cyprine_eip" {
  instance = aws_instance.cyprine_heroes.id
  domain   = "vpc"

  tags = {
    Name = "${var.project_name}-eip"
  }

  depends_on = [aws_instance.cyprine_heroes]
  
  # Prevent accidental deletion of EIP
  lifecycle {
    prevent_destroy = true
  }
}