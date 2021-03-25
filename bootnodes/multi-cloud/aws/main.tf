
provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region     = var.region
}

# Create a VPC
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public_subnet" {
  availability_zone = var.az
  vpc_id = aws_vpc.vpc.id
  cidr_block = var.public_subnet_cidr
}

# Security group restrictions
resource "aws_security_group" "sg" {
  name        = "full_node_sg"
  description = "Allow traffic ... for now."
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_network_acl" "acl" {
  vpc_id = aws_vpc.vpc.id
  subnet_ids = [
    aws_subnet.public_subnet.id
  ]

  egress {
    protocol   = "-1"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = "-1"
    rule_no    = 201
    action     = "allow"
    ipv6_cidr_block = "::/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "-1"
    rule_no    = 101
    action     = "allow"
    ipv6_cidr_block = "::/0"
    from_port  = 0
    to_port    = 0
  }
}

resource "aws_key_pair" "admin_key_pair" {
  key_name   = "admin_key_pair"
  public_key = file(var.public_key_file)
  depends_on = [var.module_depends_on]
}

resource "aws_instance" "instance" {
  count                       = var.instance_count
  ami                         = var.instance_ami
  availability_zone           = var.az
  ebs_optimized               = true
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.admin_key_pair.key_name
  vpc_security_group_ids      = [aws_security_group.sg.id]
  subnet_id                   = aws_subnet.public_subnet.id
  associate_public_ip_address = true

  root_block_device {
    volume_size               = 40
    delete_on_termination     = true
  }
}


resource "aws_internet_gateway" "ig_gw" {
  vpc_id = aws_vpc.vpc.id
}



# resource "aws_lb" "lb_rpc" {
#   name                       = "full-node-ext-rpc-load-balancer"
#   internal                   = false
#   load_balancer_type         = "network"
#   drop_invalid_header_fields = true
#   subnets                    = [aws_subnet.public_subnet.id]
#   idle_timeout               = 60
# }

# resource "aws_lb_target_group" "lbtg_rpc" {
#   name     = "full-node-ext-rpc-lb-tg-rpc"
#   port     = 9933
#   protocol = "TCP"
#   vpc_id   = aws_vpc.vpc.id

#   health_check {
#     protocol = "TCP"
#     port = 9933
#   }
# }

# resource "aws_lb_listener" "lbl_rpc" {
#   load_balancer_arn = aws_lb.lb_rpc.arn
#   port              = 9933
#   protocol          = "TCP"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.lbtg_rpc.arn
#   }
# }

# resource "aws_lb_target_group_attachment" "lbtga_rpc" {
#   count            = length(aws_instance.instance)
#   target_group_arn = aws_lb_target_group.lbtg_rpc.arn
#   target_id        = aws_instance.instance[count.index].id
#   port             = 9933
# }

# resource "aws_lb" "lb_ws" {
#   name                       = "full-node-ext-ws-load-balancer"
#   internal                   = false
#   load_balancer_type         = "network"
#   drop_invalid_header_fields = true
#   subnets                    = [aws_subnet.public_subnet.id]
#   idle_timeout               = 60
# }

# resource "aws_lb_target_group" "lbtg_ws" {
#   name     = "full-node-ext-ws-lb-tg"
#   port     = 9944
#   protocol = "TCP"
#   vpc_id   = aws_vpc.vpc.id

#   health_check {
#     protocol = "TCP"
#     port = 9944
#   }
# }

# resource "aws_lb_listener" "lbl_ws" {
#   load_balancer_arn = aws_lb.lb_ws.arn
#   port              = 9944
#   protocol          = "TCP"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.lbtg_ws.arn
#   }
# }

# resource "aws_lb_target_group_attachment" "lbtga_ws" {
#   count            = length(aws_instance.instance)
#   target_group_arn = aws_lb_target_group.lbtg_ws.arn
#   target_id        = aws_instance.instance[count.index].id
#   port             = 9944
# }

# resource "aws_lb" "lb_p2p" {
#   name                       = "authority-node-ext-gossip-lb"
#   internal                   = false
#   load_balancer_type         = "network"
#   drop_invalid_header_fields = true
#   subnets                    = [aws_subnet.public_subnet.id]
#   idle_timeout               = 60
# }

# resource "aws_lb_target_group" "lbtg_p2p" {
#   name     = "authority-node-ext-gossip-lb-tg"
#   port     = 30333
#   protocol = "TCP"
#   vpc_id   = aws_vpc.vpc.id

#   health_check {
#     protocol = "TCP"
#     port = 30333
#   }
# }

# resource "aws_lb_listener" "lbl_p2p" {
#   load_balancer_arn = aws_lb.lb_p2p.arn
#   port              = 30333
#   protocol          = "TCP"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.lbtg_p2p.arn
#   }
# }

# resource "aws_lb_target_group_attachment" "lbtga_p2p" {
#   count            = length(aws_instance.instance)
#   target_group_arn = aws_lb_target_group.lbtg_p2p.arn
#   target_id        = aws_instance.instance[count.index].id
#   port             = 30333
# }



resource "aws_route_table" "public_ig_route" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ig_gw.id
  }
}

resource "aws_route_table_association" "public_subnet_ig_route_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_ig_route.id
}




