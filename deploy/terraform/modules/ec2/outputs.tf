output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.cyprine_heroes.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.cyprine_heroes.public_ip
}

output "elastic_ip" {
  description = "Elastic IP address"
  value       = aws_eip.cyprine_eip.public_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.cyprine_heroes.public_dns
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.cyprine_sg.id
}

output "ssh_connection_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ~/.ssh/${var.key_name}.pem ubuntu@${aws_eip.cyprine_eip.public_ip}"
}

output "application_url" {
  description = "URL of the application"
  value       = "http://${aws_eip.cyprine_eip.public_ip}"
}

output "application_https_url" {
  description = "HTTPS URL of the application (after SSL setup)"
  value       = "https://${aws_eip.cyprine_eip.public_ip}"
}