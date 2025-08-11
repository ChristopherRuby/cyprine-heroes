output "instance_id" {
  description = "ID of the EC2 instance"
  value       = module.cyprine_ec2.instance_id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = module.cyprine_ec2.instance_public_ip
}

output "elastic_ip" {
  description = "Elastic IP address (fixed)"
  value       = module.cyprine_ec2.elastic_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = module.cyprine_ec2.instance_public_dns
}

output "security_group_id" {
  description = "ID of the security group"
  value       = module.cyprine_ec2.security_group_id
}

output "ssh_connection_command" {
  description = "SSH command to connect to the instance"
  value       = module.cyprine_ec2.ssh_connection_command
}

output "application_url" {
  description = "URL of the application (HTTP)"
  value       = module.cyprine_ec2.application_url
}

output "application_https_url" {
  description = "URL of the application (HTTPS, after SSL setup)"
  value       = module.cyprine_ec2.application_https_url
}

# Useful information for post-deployment
output "deployment_info" {
  description = "Important deployment information"
  value = {
    region           = var.aws_region
    instance_type    = var.instance_type
    volume_size      = var.volume_size
    environment      = var.environment
    elastic_ip       = module.cyprine_ec2.elastic_ip
    ssh_command      = module.cyprine_ec2.ssh_connection_command
    app_url          = module.cyprine_ec2.application_url
    setup_log        = "ssh and run: sudo tail -f /var/log/cyprine-setup.log"
    health_check     = "ssh and run: ./check-status.sh"
  }
}