
output "public_ip_address" {
  description = "The public ip of the instance."
  value       = aws_instance.instance.*.public_ip
}
