
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
  ingress_with_self = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "internal"
      self        = true
    }
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
  vpc_security_group_ids      = [module.default_sg.security_group_id]
  subnet_id                   = tolist(data.aws_subnet_ids.all[0].ids)[0]
  associate_public_ip_address = true
  root_block_device = [
    {
      volume_type           = var.volume_type
      volume_size           = var.volume_size
      delete_on_termination = true
    },
  ]
  key_name = aws_key_pair.key_pair[0].key_name
}

# route53 record | certificate | load balancer
data "aws_route53_zone" "default" {
  count        = var.create && var.create_lb && var.create_53_acm ? 1 : 0
  name         = var.domain_name
  private_zone = false
}

resource "aws_route53_record" "default" {
  count   = var.create && var.create_lb && var.create_53_acm ? 1 : 0
  zone_id = data.aws_route53_zone.default[0].zone_id
  name    = var.route53_record_name
  type    = "A"
  alias {
    name                   = module.alb.lb_dns_name
    zone_id                = module.alb.lb_zone_id
    evaluate_target_health = true
  }
}

module "acm" {
  source              = "terraform-aws-modules/acm/aws"
  create_certificate  = var.create && var.create_lb && var.create_53_acm
  domain_name         = var.domain_name
  zone_id             = length(data.aws_route53_zone.default)>0 ? data.aws_route53_zone.default[0].id : ""
  wait_for_validation = false
  subject_alternative_names = [
    "*.${var.domain_name}",
    "*.rpc.testnet.${var.domain_name}",
  ]
}

module "alb" {
  source    = "terraform-aws-modules/alb/aws"
  name      = "alb-${var.id}"
  create_lb = var.create && var.create_lb

  load_balancer_type = "application"
  internal           = false
  vpc_id             = data.aws_vpc.default[0].id
  subnets            = data.aws_subnet_ids.all[0].ids
  security_groups    = [module.default_sg.security_group_id]

  target_groups = [
    {
      name_prefix      = "rpc-"
      backend_protocol = "HTTP"
      backend_port     = 9933
      target_type      = "instance"
      targets = [
        for id in module.ec2.id : {
          target_id = id
          port      = 9933
        }
      ]
      health_check = {
        enabled = true
        interval = 30
        path = "/metrics"
        port = 9090
        healthy_threshold = 3
        unhealthy_threshold = 3
        timeout = 5
        protocol = "HTTP"
        matcher = "200"
      }
    },
    {
      name_prefix      = "ws-"
      backend_protocol = "HTTP"
      backend_port     = 9944
      target_type      = "instance"
      targets = [
        for id in module.ec2.id : {
          target_id = id
          port      = 9944
        }
      ]
      health_check = {
        enabled = true
        interval = 30
        path = "/metrics"
        port = 9090
        healthy_threshold = 3
        unhealthy_threshold = 3
        timeout = 5
        protocol = "HTTP"
        matcher = "200"
      }
    }
  ]

  https_listeners = var.create_53_acm ? [
    {
      port               = 9933
      protocol           = "HTTPS"
      certificate_arn    = module.acm.acm_certificate_arn
      target_group_index = 0
    },
    {
      port               = 9944
      protocol           = "HTTPS"
      certificate_arn    = module.acm.acm_certificate_arn
      target_group_index = 1
    }
  ] : var.certificate_arn!="" ? [
    {
      port               = 9933
      protocol           = "HTTPS"
      certificate_arn    = var.certificate_arn
      target_group_index = 0
    },
    {
      port               = 9944
      protocol           = "HTTPS"
      certificate_arn    = var.certificate_arn
      target_group_index = 1
    }
  ] : []

  http_tcp_listeners = !var.create_53_acm && var.certificate_arn=="" ? [
    {
      port               = 9933
      protocol           = "HTTP"
      target_group_index = 0
    },
    {
      port               = 9944
      protocol           = "HTTP"
      target_group_index = 1
    }
  ] : []
}
