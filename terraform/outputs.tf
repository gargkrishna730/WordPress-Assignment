output "instance_public_ip" {
  value = aws_instance.wordpress.public_ip
}

output "vpc_id" {
  value = aws_vpc.wordpress_vpc.id
}

output "elastic_ip" {
  value       = aws_eip.wordpress_eip.public_ip
  description = "Elastic IP assigned to the WordPress instance"
} 