Hello

This Terraform module will create:
5 ec2 instances with Opensearch installed and configured:
    3 data nodes
    1 master
    1 dashborad
3 ebs on size 30o GB for every data node.
5 route53 records
OPTINAL:
    vpc
    security_group
if you wolud like that the moudle will create vpc and security_group please verify "create_vpc" var == true.

To run this moudle you need route 53.

If you wolud like to add more nodes, notice that you need to add them also on 'conf_setup.sh' on opensearch.yml (discovery.seed_hosts) and on opensearch-dashborads.yml (opensearch.hosts) .

steps to deploy :
    on /modules/opensearch/variables.tf :
        on 'variable "opensearch_node"' :
            insert your cluster detailes, you can add more nodes if you want, please keep the data and master nodes on t2.xlarge instance_type or larger.
            ami - default centos 8 (defult recommendation).
    on ./main.tf (root)
            declare all vars (as your aws env)
    after all vars are declared please run:
    terraform init
    terraform plan
    terraform apply


To check your opensearch cluster run:
    curl -XGET https://master-opensearch.domain.com:9200 -u 'admin:admin' --insecure

    your output should be something like this:
        {
        "name" : "master-opensearch.domain.com",
        "cluster_name" : "opensearch-cluster",
        "cluster_uuid" : "pAv5XirfRCC1yD6C6wXXXXXXX",
        "version" : {
            "distribution" : "opensearch",
            "number" : "1.0.0",
            "build_type" : "tar",
            "build_hash" : "34550c5b17124ddc59458ef774f6b43XXXXXXXX",
            "build_date" : "2021-07-02T23:22:21.383695Z",
            "build_snapshot" : false,
            "lucene_version" : "8.8.2",
            "minimum_wire_compatibility_version" : "6.8.0",
            "minimum_index_compatibility_version" : "6.0.0-beta1"
        },
        "tagline" : "The OpenSearch Project: https://opensearch.org/"
        }


To reach the dashborad server:
    https://dashboard-opensearch.domain.com:5601
        opensearch.username: "admin"
        opensearch.password: "admin"

To connect your hosts:
    sudo ssh -i key.pem centos@node1-opensearch.domain.com

to delete all resources:
    terraform destroy





