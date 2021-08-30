
variable "opensearch_node"{
    description = "map of nodes configuration"
    type        = map(map(string))
    default     = {
        master = {
            name = "master-opensearch"
            ami  = "ami-059f1cc52e6c85908"
            instance_type = "t2.xlarge"
            disk_size     = "10"
            role          = "master"
        },
        node1 = {
            name = "node1-opensearch"
            ami  = "ami-059f1cc52e6c85908"
            instance_type = "t2.xlarge"
            disk_size     = "30"
            role          = "data"
        },
        node2 = {
            name = "node2-opensearch"
            ami  = "ami-059f1cc52e6c85908"
            instance_type = "t2.xlarge"
            disk_size     = "30"
            role          = "data"
            
        },
        node3 = {
            name = "node3-opensearch"
            ami  = "ami-059f1cc52e6c85908"
            instance_type = "t2.xlarge"
            disk_size     = "30"
            role          = "data"
        },
        dashboard = {
            name = "dashboard-opensearch"
            ami  = "ami-059f1cc52e6c85908"
            instance_type = "t2.xlarge"
            disk_size     = "10"
            role          = "dashboard"
        }
    }
}   

variable "create_vpc" {
    type            = bool
    description     = "do you want to create a new vpc?"
    default         = false
}

variable "env" {
    type            = string
    description     = "env tag"
    default         = "dev"
}

variable "cluster_name" {
    type            = string
    description     = "cluster_name"
    default         = "opensearch-cluster"
}  

variable "key_name" {
    type            = string
    description     = "Private key"
}  

variable "vpc_id" {
    type            = list(string)
    description     = "vcp id"
}  

variable "subnet_id" {
    type            = string
    description     = "subnet id"
}  

variable "path_to_data" {
    type            = string
    description     = "path_to_data"
    default         = "/tmp/data"
}  

variable "route53_zone" {
    type            = string
    description     = "route53 zone id"
}

variable "route53_domain" {
    type            = string
    description     = "your route53 zonde domain (dom.com)"
}