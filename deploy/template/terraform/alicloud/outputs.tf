
# VSwitch  ID
output "vswitch_ids" {
  description = "The vswitch id in which the instance."
  value       = alicloud_vswitch.vswitch.id
}

# Output the IDs of the ECS instances created
output "instance_ids" {
  description = "The instance ids."
  value       = alicloud_instance.instance.id
}

output "instance_names" {
  description = "The instance names."
  value       = alicloud_instance.instance.instance_name
}

output "security_group_ids" {
  description = "The security group ids in which the instance."
  value       = alicloud_instance.instance.security_groups
}

output "private_ip" {
  description = "The private ip of the instance."
  value       = alicloud_instance.instance.private_ip
}

output "public_ip" {
  description = "The public ip of the instance."
  value       = alicloud_instance.instance.public_ip
}
