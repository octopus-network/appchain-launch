
provider "alicloud" {
  access_key = var.access_key
  secret_key = var.secret_key
  region     = var.region
}

# VPC + VSwitch + Security Group
data "alicloud_zones" "default" {
  available_disk_category     = "cloud_efficiency"
  available_resource_creation = "VSwitch"
}

resource "alicloud_vpc" "vpc" {
  name       = var.vpc_name
  cidr_block = "172.16.0.0/12"
}

resource "alicloud_vswitch" "vswitch" {
  name              = var.vswitch_name
  vpc_id            = alicloud_vpc.vpc.id
  cidr_block        = "172.16.0.0/24"
  availability_zone = data.alicloud_zones.default.zones[0].id
}

resource "alicloud_security_group" "default" {
  name        = var.security_group_name
  vpc_id      = alicloud_vpc.vpc.id
}

resource "alicloud_security_group_rule" "allow_ssh" {
  security_group_id = alicloud_security_group.default.id
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "22/22"
  priority          = 1
  cidr_ip           = "0.0.0.0/0"
}

# resource "alicloud_security_group_rule" "allow_https" {
#   security_group_id = alicloud_security_group.default.id
#   type              = "ingress"
#   ip_protocol       = "tcp"
#   nic_type          = "intranet"
#   policy            = "accept"
#   port_range        = "443/443"
#   priority          = 1
#   cidr_ip           = "0.0.0.0/0"
# }

# ECS
data "alicloud_images" "ubuntu" {
  most_recent = true
  name_regex  = "^ubuntu_18.*64"
}

resource "alicloud_key_pair" "key_pair" {
  key_name   = var.key_name
  public_key = var.public_key
}

resource "alicloud_instance" "instance" {
  instance_name              = var.instance_name
  security_groups            = alicloud_security_group.default.*.id
  vswitch_id                 = alicloud_vswitch.vswitch.id
  image_id                   = data.alicloud_images.ubuntu.ids.0

  # https://help.aliyun.com/document_detail/25378.html
  instance_type              = var.instance_type

  system_disk_category       = "cloud_efficiency"
  system_disk_size           = 40

  internet_max_bandwidth_out = 10
  internet_charge_type       = "PayByTraffic"
  
  # https://help.aliyun.com/document_detail/25382.html
#   data_disks {
#     size              = 20
#     category          = "cloud_essd"
#     performance_level = "PL1"
#     encrypted         = true
#   }

  key_name = alicloud_key_pair.key_pair.key_name

  # Ansible
  provisioner "local-exec" {
    command = "sleep 30; ansible-playbook -i '${self.public_ip},' -v ../ansible/playbooks/chain.yml"
    environment = {
      ANSIBLE_CONFIG = "../ansible/ansible.cfg"
    }
  }
}
