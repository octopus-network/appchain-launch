resource "random_id" "this" {
  byte_length = 8
}

resource "null_resource" "ssh-keygen" {
  triggers = {
    # apply_time = timestamp()
    ssh_key = "${random_id.this.id}"
  }

  provisioner "local-exec" {
    command = "ssh-keygen -t rsa -P '' -f ${random_id.this.id} <<<y"
  }
  
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
rm -f ${self.triggers.ssh_key}
rm -f ${self.triggers.ssh_key}.pub
EOT
  }
}

locals {
  inventory_template_vars = {
    public_ips=alicloud_instance.instance.*.public_ip,
    private_ips=alicloud_instance.instance.*.private_ip,
    hostnames=alicloud_instance.instance.*.host_name,
    peer_ids=var.p2p_peer_ids
  }
}

resource "null_resource" "inventory_template" {
  triggers = {
    apply_time = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOT
cat<<EOF > ansible_inventory
${templatefile(var.inventory_template, local.inventory_template_vars)}
EOF
EOT
  }

    provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
rm -f ansible_inventory
EOT
  }
}

module "ansible" {
  source = "github.com/insight-infrastructure/terraform-ansible-playbook.git"

  ips                = alicloud_instance.instance.*.public_ip
  playbook_file_path = "bootnodes.yml"
  user               = "root"
  private_key_path   = "${random_id.this.id}"
  inventory_file     = "ansible_inventory"
  playbook_vars      = {
    chain_spec   = var.chain_spec
    rpc_port     = var.rpc_port 
    ws_port      = var.ws_port
    p2p_port     = var.p2p_port
    base_image   = var.base_image
    start_cmd    = var.start_cmd
  }

  module_depends_on  = [
    var.cloud_vendor == "alicoud" ? alicloud_instance.instance : var.cloud_vendor == "aws" ? null : null,
    null_resource.inventory_template
  ]
}
