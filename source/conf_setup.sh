#! /bin/bash


sudo touch /tmp/logs
sudo chmod 777 /tmp/logs

#check if alleardy installed
FILE=/tmp/first_install
if [ -f "$FILE" ]; then
    echo "$FILE exist"
    exit 0
fi

echo ${node_role} >> /tmp/logs
echo ${domain} >> /tmp/logs
echo ${cluster_name} >> /tmp/logs
echo ${path_to_data} >> /tmp/logs

if [[ "${node_role}" == "data" || "${node_role}" == "master" ]]
then
    echo "insert the data - master conf" >> /tmp/logs
    #download and untar the opensearch.tar.gz
    curl https://artifacts.opensearch.org/releases/bundle/opensearch/1.0.0/opensearch-1.0.0-linux-x64.tar.gz --output /tmp/opensearch.tar.gz >> /tmp/logs
    sudo mkdir /tmp/opensearch
    sudo tar -xvf /tmp/opensearch.tar.gz --directory /tmp/opensearch

    
    #rm old opensearch config yml
    sudo rm -rf /tmp/opensearch/opensearch-1.0.0/config/opensearch.yml

    echo "basic conf" >> /tmp/logs
    #basic config
    sudo sysctl -w vm.max_map_count=262144
    sudo hostname "${node_name}"
    export ipaddr=$(hostname -I)

    if [ "${node_role}" == "data" ] 
    then
        echo "config data" >> /tmp/logs
        #write new opensearch.yml conf
        cat <<EOT > /tmp/opensearch.yml
cluster.name: ${cluster_name}
node.name: ${node_name}
discovery.seed_hosts: ["node1-opensearch.${domain}","node2-opensearch.${domain}","node3-opensearch-test.${domain}","master-opensearch.${domain}","dashboard-opensearch.${domain}"]
cluster.initial_master_nodes: ["master-opensearch.${domain}"]
network.host: $ipaddr
path.data: ${path_to_data}
EOT
fi

    if [ "${node_role}" == "master" ] 
    then
        echo "config master" >> /tmp/logs
        #write new opensearch.yml conf
        cat <<EOT > /tmp/opensearch.yml
cluster.name: ${cluster_name}
node.name: ${node_name}
discovery.seed_hosts: ["node1-opensearch.${domain}","node2-opensearch.${domain}","node3-opensearch-test.${domain}","master-opensearch.${domain}","dashboard-opensearch.${domain}"]
cluster.initial_master_nodes: ["master-opensearch.${domain}"]
network.host: $ipaddr
EOT
fi

    #mv new opensearch.yml to conf dir
    sudo mv /tmp/opensearch.yml /tmp/opensearch/opensearch-1.0.0/config

    #give to centos user premmisions 
    sudo chown -R centos:root /tmp/opensearch


    sudo chown centos:root /tmp/opensearch/opensearch-1.0.0/config/opensearch.keystore 
    sudo chmod -R 755 /dev/shm
    
    mkdir ${path_to_data}
    if [ "${node_role}" == "data" ]
    then
        echo "config mount ${path_to_data}" >> /tmp/logs
        sudo mkfs -t xfs /dev/xvdb
        sudo mount /dev/xvdb ${path_to_data}
        sudo chown -R centos:root ${path_to_data}
        sudo mount -a
    fi

    
    #run opensearch installtion
    bash /tmp/opensearch/opensearch-1.0.0/opensearch-tar-install.sh >> /tmp/logs


    #create end_of_install file
    sudo touch /tmp/first_install


    sudo sleep 5
    
    sudo chown -R centos:root /tmp/opensearch


    echo "create Opensearch service" >> /tmp/logs   
    sudo touch /etc/systemd/system/opensearch.service
    sudo chmod 777 /etc/systemd/system/opensearch.service
    sudo echo "
[Unit]
Description=Opensearch service
After=network.target
StartLimitIntervalSec=0
[Service]
Type=simple
Restart=always
RestartSec=1
User=centos
ExecStart=/bin/bash -c '/tmp/opensearch/opensearch-1.0.0/bin/opensearch'

[Install]
WantedBy=multi-user.target
" >> /etc/systemd/system/opensearch.service


    sudo systemctl daemon-reload
    sudo systemctl enable opensearch
    sudo systemctl start opensearch

fi



if [ "${node_role}" == "dashboard" ]
then

    sudo hostname "${node_name}"
    bash

    #download and untar the dashborad component 
    curl https://artifacts.opensearch.org/releases/bundle/opensearch-dashboards/1.0.0/opensearch-dashboards-1.0.0-linux-x64.tar.gz --output /tmp/opensearch-dashboard.tar.gz
    sudo mkdir /tmp/opensearch-dashboard
    sudo tar -xvf /tmp/opensearch-dashboard.tar.gz --directory /tmp/opensearch-dashboard
    #edit opensearch_dashborad conf yml.
    cat <<EOT > /tmp/opensearch-dashboard/opensearch-dashboards-1.0.0/config/opensearch_dashboards.yml
# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License is located at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# or in the "license" file accompanying this file. This file is distributed
# on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
# express or implied. See the License for the specific language governing
# permissions and limitations under the License.

# Description:
# Default configuration for OpenSearch Dashboards

opensearch.hosts: ["https://node1-opensearch.${domain}:9200","https://node2-opensearch.${domain}:9200","https://node3-opensearch.${domain}:9200","https://master-opensearch.${domain}:9200"]
opensearch.ssl.verificationMode: none
opensearch.username: "kibanaserver"
opensearch.password: "kibanaserver"
opensearch.requestHeadersWhitelist: [ authorization,securitytenant ]

opensearch_security.multitenancy.enabled: true
opensearch_security.multitenancy.tenants.preferred: ["Private", "Global"]
opensearch_security.readonly_mode.roles: ["kibana_read_only"]
# Use this setting if you are running kibana without https
opensearch_security.cookie.secure: false
server.host: ${node_name}
EOT


    sleep 5
    sudo chown -R centos:root /tmp/opensearch-dashboard

    echo "create Opensearch-Dashboard service" >> /tmp/logs

    sudo touch /etc/systemd/system/opensearch-dashboard.service
    sudo chmod 777 /etc/systemd/system/opensearch-dashboard.service

    sudo echo "
[Unit]
Description=Opensearch service
After=network.target
StartLimitIntervalSec=0
[Service]
Type=simple
Restart=always
RestartSec=1
User=centos
ExecStart=/bin/bash -c 'tmp/opensearch-dashboard/opensearch-dashboards-1.0.0/bin/opensearch-dashboards' 
[Install]
WantedBy=multi-user.target
" >> /etc/systemd/system/opensearch-dashboard.service


    sudo systemctl daemon-reload
    sudo systemctl enable opensearch-dashboard
    sudo systemctl start opensearch-dashboard

fi

echo "done running" >> /tmp/logs
        