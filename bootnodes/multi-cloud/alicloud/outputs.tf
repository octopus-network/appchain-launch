
output "public_ip_address" {
  description = "The public ip of the instance."
  value       = alicloud_instance.instance.*.public_ip
}
