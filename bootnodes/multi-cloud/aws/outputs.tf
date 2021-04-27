
output "public_ip_address" {
  description = "The public ip of the instance."
  value       = module.ec2.public_ip
}

output "lb_dns_name" {
  description = "The DNS name of the load balancer."
  value       = var.create && var.create_lb ? module.nlb.lb_dns_name : ""
}
