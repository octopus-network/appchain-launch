
provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region     = var.region
}

# module "vpc" {
#   source     = "terraform-aws-modules/vpc/aws"
#   create_vpc = false
#   name       = "vpc-${var.id}"

#   cidr               = var.vpc_cidr
#   azs                = var.availability_zones
#   private_subnets    = var.private_cidrs
#   public_subnets     = var.public_cidrs
#   enable_nat_gateway = true
#   enable_vpn_gateway = true
# }

data "aws_vpc" "default" {
  count   = var.create ? 1 : 0
  default = true
}

data "aws_subnet_ids" "all" {
  count  = var.create ? 1 : 0
  vpc_id = data.aws_vpc.default[0].id
}

data "aws_ami" "ubuntu" {
  count       = var.create ? 1 : 0
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"]
}


module "default_sg" {
  source = "terraform-aws-modules/security-group/aws"
  name   = "default-sg-${var.id}"
  create = var.create

  vpc_id                   = data.aws_vpc.default[0].id
  egress_cidr_blocks       = ["0.0.0.0/0"]
  egress_ipv6_cidr_blocks  = ["::/0"]
  egress_rules             = ["all-all"]
  ingress_cidr_blocks      = ["0.0.0.0/0"]
  ingress_rules            = ["ssh-tcp"]
  ingress_with_cidr_blocks = [
    {
      from_port   = 9933
      to_port     = 9933
      protocol    = "tcp"
      description = "rpc port"
      cidr_blocks = "0.0.0.0/0"
      # ipv6_cidr_block = "::/0"
      rule_no     = 101
    },
    {
      from_port   = 9944
      to_port     = 9944
      protocol    = "tcp"
      description = "ws port"
      cidr_blocks = "0.0.0.0/0"
      # ipv6_cidr_block = "::/0"
      rule_no     = 102
    },
    {
      from_port   = 30333
      to_port     = 30333
      protocol    = "tcp"
      description = "p2p port"
      cidr_blocks = "0.0.0.0/0"
      # ipv6_cidr_block = "::/0"
      rule_no     = 103
    },
  ]
}

resource "aws_key_pair" "key_pair" {
  count      = var.create ? 1 : 0
  key_name   = "kp-${var.id}"
  public_key = file(var.public_key_file)
  # depends_on = [var.module_depends_on]
}

module "ec2" {
  source = "terraform-aws-modules/ec2-instance/aws"
  name   = "ec2-${var.id}"

  ami                         = data.aws_ami.ubuntu[0].id
  instance_count              = var.create ? var.instance_count : 0
  instance_type               = var.instance_type
  monitoring                  = true
  vpc_security_group_ids      = [module.default_sg.this_security_group_id]
  subnet_id                   = tolist(data.aws_subnet_ids.all[0].ids)[0]
  associate_public_ip_address = true
  root_block_device = [
    {
      volume_type           = var.volume_type
      volume_size           = var.volume_size
      delete_on_termination = true
    },
  ]
  key_name                    = aws_key_pair.key_pair[0].key_name
  iam_instance_profile        = aws_iam_instance_profile.default.name
}
