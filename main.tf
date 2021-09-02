
module "opensearch-opster" {
  source = "./modules/opensearch"
  cluster_name = "opensearch-cluster"
  key_name = "key"
  create_vpc = false
  sg_vpc_id = [""]
  subnet_id = ""
  route53_zone = ""
  route53_domain = "dom.com"
  path_to_data = "/tmp/data"
  cidr_block  = "10.0.0.0/16"
  subnet_availability_zone = ""
}


