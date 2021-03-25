
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
  cidr_block = "172.16.0.0/12"
}

resource "alicloud_vswitch" "vswitch" {
  vpc_id            = alicloud_vpc.vpc.id
  cidr_block        = "172.16.0.0/24"
  availability_zone = data.alicloud_zones.default.zones[0].id
}

resource "alicloud_security_group" "default" {
  vpc_id = alicloud_vpc.vpc.id
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

resource "alicloud_security_group_rule" "allow_9933" {
  security_group_id = alicloud_security_group.default.id
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "9933/9933"
  priority          = 1
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "allow_9944" {
  security_group_id = alicloud_security_group.default.id
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "9944/9944"
  priority          = 1
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "allow_30333" {
  security_group_id = alicloud_security_group.default.id
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "30333/30333"
  priority          = 1
  cidr_ip           = "0.0.0.0/0"
}

# ECS
data "alicloud_images" "ubuntu" {
  most_recent = true
  name_regex  = "^ubuntu_20.*64"
}

resource "alicloud_key_pair" "key_pair" {
  key_name   = "kp-12345678"
  public_key = file(var.public_key_file)
  depends_on = [var.module_depends_on]
}

resource "alicloud_instance" "instance" {
  count                      = var.instance_count
  instance_name              = format("alicloud_instance-%03d", count.index + 1)
  security_groups            = alicloud_security_group.default.*.id
  vswitch_id                 = alicloud_vswitch.vswitch.id
  image_id                   = data.alicloud_images.ubuntu.ids.0
  # https://help.aliyun.com/document_detail/25378.html
  instance_type              = var.instance_type
  system_disk_category       = "cloud_efficiency"
  system_disk_size           = 40
  internet_max_bandwidth_out = 10
  internet_charge_type       = "PayByTraffic"
  key_name                   = alicloud_key_pair.key_pair.key_name
}
