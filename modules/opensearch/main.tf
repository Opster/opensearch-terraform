
resource "aws_vpc" "opensearch_vpc" {
  count            = (var.create_vpc  == true ? 1 : 0)
  cidr_block       = var.cidr_block

  tags = {
    Name = "${var.cluster_name}-vpc"
    cluster = var.cluster_name

  }
}

resource "aws_subnet" "opensearch_subnet" {
  count            = (var.create_vpc  == true ? 1 : 0)
  vpc_id            = aws_vpc.opensearch_vpc[count.index].id
  cidr_block        = var.cidr_block
  availability_zone = var.subnet_availability_zone

  tags = {
    Name = "${var.cluster_name}-subnet"
    cluster = var.cluster_name

  }
}

resource "aws_security_group" "opensearch_security_group" {
  count            = (var.create_vpc  == true ? 1 : 0)
  vpc_id           = aws_vpc.opensearch_vpc[count.index].id

  tags = {
    Name    = "${var.cluster_name}-sg"
    cluster = var.cluster_name
  }

  # ssh access from everywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.opensearch_vpc[0].cidr_block]
  }

  # inter-cluster communication over ports 9200-9400
  ingress {
    from_port = 9200
    to_port   = 9400
    protocol  = "tcp"
    self      = true
  }
  # allow kibana (opensearch-dashborad) port 5601
 ingress {
    from_port = 5601
    to_port   = 5601
    protocol  = "tcp"
    self      = true
  }
  # allow inter-cluster ping
  ingress {
    from_port = 8
    to_port   = 0
    protocol  = "icmp"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


data "template_file" "conf_setup" {
  for_each             = var.opensearch_node    
  template             = file("./source/conf_setup.sh")
  vars = {
    cluster_name       = var.cluster_name
    node_name          = "${each.value.name}.${var.route53_domain}"
    node_role          = each.value.role
    path_to_data       = var.path_to_data
    domain             = "${var.route53_domain}"
  }
}


resource  "aws_instance" "opensearch_cluster" {
  for_each = var.opensearch_node
  ami                    = each.value.ami
  key_name               = var.key_name
  instance_type          = each.value.instance_type
  monitoring             = true
  subnet_id              = (var.create_vpc  == true ? aws_subnet.opensearch_subnet[0].id : var.subnet_id)
  vpc_security_group_ids = (var.create_vpc  == true ? [aws_security_group.opensearch_security_group[0].id] : var.sg_vpc_id)
  user_data              = data.template_file.conf_setup[each.key].rendered 
  ebs_block_device {
    device_name          = "/dev/sdb" 
    volume_size          = each.value.disk_size 
    tags = {
      Name               = each.value.name
    }
  }
  
  tags = {
    Terraform   = "true"
    part_of     = var.cluster_name
    Name        = "${each.value.name}"
    role        = "${each.value.role}"
  }

}


resource "aws_route53_record" "opensearch-test" {
  for_each = aws_instance.opensearch_cluster

  zone_id = var.route53_zone
  name    = "${each.value.tags.Name}.${var.route53_domain}"
  type    = "A"
  ttl     = "300"
  records = [each.value.private_ip]
}


