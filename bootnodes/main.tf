resource "random_id" "this" {
  byte_length = 8
}

resource "null_resource" "ssh-keygen" {
  triggers = {
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

# resource "null_resource" "generate-node-key" {
#   triggers = {
#     ssh_key = "${random_id.this.id}"
#   }

#   provisioner "local-exec" {
#     command = <<-EOT
# docker run --rm -v $(pwd)/keys:/tmp/keys octopus/subkey-tool:1.0.0 generate-node-key ${var.bootnodes}
# EOT
#   }
# }


module "cloud" {
  source            = "./multi-cloud/aws"

  access_key        = var.access_key
  secret_key        = var.secret_key
  instance_count    = length(var.p2p_peer_ids)
  public_key_file   = abspath("${random_id.this.id}.pub")
  module_depends_on = [null_resource.ssh-keygen]
}


locals {
  inventory_template_vars = {
    public_ips = module.cloud.public_ip_address,
    peer_ids   = var.p2p_peer_ids
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

  ips                = module.cloud.public_ip_address
  playbook_file_path = "bootnodes.yml"
  user               = var.user
  private_key_path   = "${random_id.this.id}"
  inventory_file     = "ansible_inventory"
  playbook_vars      = {
    chain_spec    = var.chain_spec
    rpc_port      = var.rpc_port 
    ws_port       = var.ws_port
    p2p_port      = var.p2p_port
    base_image    = var.base_image
    start_cmd     = var.start_cmd
    wasm_url      = var.wasm_url
    wasm_checksum = var.wasm_checksum
  }

  module_depends_on = [
    #var.cloud_vendor == "alicoud" ? alicloud_instance.instance : var.cloud_vendor == "aws" ? null : null,
    null_resource.inventory_template
  ]
}
