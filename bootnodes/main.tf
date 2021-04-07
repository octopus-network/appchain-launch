resource "random_id" "this" {
  byte_length = 8
}

resource "null_resource" "workspace" {
  triggers = {
    workspace = random_id.this.hex
  }

  provisioner "local-exec" {
    command = "mkdir -p ${random_id.this.hex}/ssh"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -rf ${self.triggers.workspace}"
  }
}

resource "null_resource" "ssh-key" {
  triggers = {
    ssh_key = random_id.this.hex
  }

  provisioner "local-exec" {
    command = "ssh-keygen -t rsa -P '' -f ${random_id.this.hex}/ssh/${random_id.this.hex} <<<y"
  }
  depends_on = [null_resource.workspace]
}

module "cloud" {
  source            = "./multi-cloud/aws"

  access_key         = var.access_key
  secret_key         = var.secret_key
  region             = var.region
  availability_zones = var.availability_zones
  instance_count     = var.instance_count
  instance_type      = var.instance_type
  volume_type        = var.volume_type
  volume_size        = var.volume_size
  kms_key_spec       = var.kms_key_spec
  kms_key_alias      = var.kms_key_alias
  public_key_file    = abspath("${random_id.this.hex}/ssh/${random_id.this.hex}.pub")
  id                 = random_id.this.hex
  module_depends_on  = [null_resource.ssh-key]
}

locals {
  keys_octoup = [
    for i in fileset(path.module, "${var.keys_octoup}/*/peer-id"): {
      peer_id = chomp(file(i))
      key_dir = dirname(abspath(i))
    }
  ]
}

resource "local_file" "ansible-inventory" {
  filename = "${random_id.this.hex}/ansible_inventory"
  content  = templatefile("${path.module}/ansible/ansible_inventory.tpl", {
    public_ips  = module.cloud.public_ip_address,
    keys_octoup = local.keys_octoup
  })
}

module "ansible" {
  source = "github.com/insight-infrastructure/terraform-ansible-playbook.git"

  user               = var.user
  ips                = module.cloud.public_ip_address
  playbook_file_path = "${path.module}/ansible/playbook.yml"
  private_key_path   = "${random_id.this.hex}/ssh/${random_id.this.hex}"
  inventory_file     = local_file.ansible-inventory.filename
  playbook_vars      = {
    chainspec_url      = var.chainspec_url
    chainspec_checksum = var.chainspec_checksum
    bootnodes          = jsonencode(var.bootnodes)
    rpc_port           = var.rpc_port 
    ws_port            = var.ws_port
    p2p_port           = var.p2p_port
    base_image         = var.base_image
    start_cmd          = var.start_cmd

    node_exporter_enabled         = var.node_exporter_enabled
    node_exporter_binary_url      = var.node_exporter_binary_url
    node_exporter_binary_checksum = var.node_exporter_binary_checksum
    node_exporter_port            = var.node_exporter_port
    node_exporter_user            = var.node_exporter_user
    node_exporter_password        = var.node_exporter_password
  }
  # module_depends_on = [local_file.ansible-inventory]
}
