output "elastic_ip" {
  description = "Elastic IP of the EC2 instance"
  value       = aws_eip.pedeai.public_ip
}

output "ssh_command" {
  description = "Command to SSH into the instance"
  value       = "ssh ubuntu@${aws_eip.pedeai.public_ip}"
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.pedeai.id
}
