resource "random_id" "this" {
  byte_length = 8
}

resource "null_resource" "workspace" {
  triggers = {
    workspace = random_id.this.id
  }

  provisioner "local-exec" {
    command = <<-EOT
mkdir -p ${random_id.this.id}/ssh
mkdir -p ${random_id.this.id}/p2p
EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -rf ${self.triggers.workspace}"
  }
}

resource "null_resource" "ssh-key" {
  triggers = {
    ssh_key = random_id.this.id
  }

  provisioner "local-exec" {
    command = "ssh-keygen -t rsa -P '' -f ${random_id.this.id}/ssh/${random_id.this.id} <<<y"
  }
  depends_on = [null_resource.workspace]
}

resource "null_resource" "p2p-key" {
  triggers = {
    ssh_key = random_id.this.id
  }

  provisioner "local-exec" {
    command = "/bin/bash generate-node-key.sh ${var.bootnodes} ${random_id.this.id}/p2p"
  }
  depends_on = [null_resource.workspace]
}


module "cloud" {
  source            = "./multi-cloud/aws"

  access_key        = var.access_key
  secret_key        = var.secret_key
  instance_count    = var.bootnodes
  public_key_file   = abspath("${random_id.this.id}/ssh/${random_id.this.id}.pub")
  module_depends_on = [null_resource.ssh-key]
}


resource "null_resource" "ansible_inventory" {
  triggers = {
    instance_ips = join(",", module.cloud.public_ip_address)
  }

  provisioner "local-exec" {
    command = <<-EOT
cat<<EOF > ${random_id.this.id}/ansible_inventory
${templatefile(var.inventory_template, {
    public_ips = module.cloud.public_ip_address,
    peer_ids   = tolist(fileset("${random_id.this.id}/p2p", "12D3*"))
  })}
EOF
EOT
  }

  depends_on = [null_resource.p2p-key]
}

module "ansible" {
  source = "github.com/insight-infrastructure/terraform-ansible-playbook.git"

  ips                = module.cloud.public_ip_address
  playbook_file_path = "bootnodes.yml"
  user               = var.user
  private_key_path   = "${random_id.this.id}/ssh/${random_id.this.id}"
  inventory_file     = "${random_id.this.id}/ansible_inventory"
  playbook_vars      = {
    workspace     = random_id.this.id
    chain_spec    = var.chain_spec
    rpc_port      = var.rpc_port 
    ws_port       = var.ws_port
    p2p_port      = var.p2p_port
    base_image    = var.base_image
    start_cmd     = var.start_cmd
    wasm_url      = var.wasm_url
    wasm_checksum = var.wasm_checksum
  }
  module_depends_on = [null_resource.ansible_inventory]
}
