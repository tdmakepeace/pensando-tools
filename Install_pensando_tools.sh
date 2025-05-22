#!/bin/bash


###
### This script installs and configures a selection of AMD tools to support the AMD Pensnado DPU
### Options for the ELK  or Broker service are the currently available.
### 
### Current support is for Ubuntu 20.04/22.04/24.04 server install or Entreprise Redhat.
### The only specific prerequisite for running this script is OpenSSH.
###
### A static IP configuration is strongly recommended, with either single or 
###  dual network interfaces.
###
### This should be run as the non-root user account created during Ubuntu server 
### installation, and utilizes sudo during the deployment process.
###
### Based on the original script hosted at: https://github.com/tdmakepeace/ELK_Single_script 
###
### To start this script from an Ubuntu server instance, run the following 
###  command:
###
###
### wget -O Install_pensando_tools.sh  https://raw.githubusercontent.com/tdmakepeace/pensando-tools/refs/heads/main/Install_pensando_tools.sh && chmod +x Install_pensando_tools.sh  &&  ./Install_pensando_tools.sh###
### 
###
###	Licensed under the Apache License, Version 2.0 (the "License");
### you may not use this file except in compliance with the License.
### You may obtain a copy of the License at
### 
###     http://www.apache.org/licenses/LICENSE-2.0
### 
### Unless required by applicable law or agreed to in writing, software
### distributed under the License is distributed on an "AS IS" BASIS,
### WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
### See the License for the specific language governing permissions and
### limitations under the License.

###	


### ELK Note:
### The recommended and supported ELK version is 8.16.1, this is the last comunitiy version published before they changed the licencing for 
### a number of features used in the Kibana dashboard.

### gitlocation base folder and root folder are all editable if you have already installed the ELK stack or broker.
### however these are expectd to be the defaults going forwrd.

### variables can be edited. 

ELK="TAG=8.16.1"
elkgitlocation="https://github.com/amd/pensando-elk.git"
elkbasefolder="pensando-elk"
brokergitlocation="https://gitlab.com/pensando/tbd/APB/apb.git"
brokerbasefolder="apb"


rootfolder="pensandotools"

###  main code area should not be modified.
	
rebootserver()
{
		echo -e "\e[0;31mRebooting the system...\n\e[0m"
		
		sleep 5
		sudo reboot
		sleep 10
		break
}

updates()
{
		
		sudo apt-get update 
		sudo NEEDRESTART_SUSPEND=1 apt-get dist-upgrade --yes 

		sleep 10
}

updatesred()
{
		subscription-manager attach --auto
		subscription-manager repos
		sudo yum update -y -q 

		sleep 10
}


basenote()
{
		## Update all the base image of Ubuntu before we progress. 
		## then installs all the dependencies and sets up the permissions for Docker
		clear
		echo -e "\nThis script will run unattended for 5-10 minutes to do the base setup of the server enviroment ready for any of the AMD Pensando tools.  It might appear to have paused, but leave it until the host reboots.\n
It is recommended to be a static IP configuration.\n" | fold -w 80 -s

	echo -e "\e[1;33mPress Ctrl+C to exit if you need to configure a static IP address, then run this script again.\n\e[0m"
  
  
		read -p "Press enter to continue...."
}

elknote()
{
	echo -e "\nThis workflow requires input to select the desired application version, optionally configure an ElastiFlow license key, and will then run unattended to deploy and configure the ELK Stack components.\n" | fold -w 80 -s
	echo -e "Please do not interrupt the script during this process, to avoid leaving the application in a partially-deployed state.\n" | fold -w 80 -s
	read -p "Press enter to continue..."
}


elkdockerupnote()
{

		echo "Access the ELK Stack application in a browser from the following URL: "
		echo -e "\e[0;31mhttp://$localip:5601\n\e[0m"
				
		echo -e "Allow 5 minutes for all the service to come up before you attempting to access the Kibana dashboards. \n" | fold -w 80 -s
		read -p "Services setup. Press enter to continue..."
		exit 0	
}

brokernote()
{
	clear 
	localip=`hostname -I | cut -d " " -f1`
	echo -e "\nThis workflow requires input to link the broker to PSM, and will then run unattended to deploy and configure the broker components.\n" | fold -w 80 -s
	echo -e "Please do not interrupt the script during this process, to avoid leaving the application in a partially-deployed state.\n" | fold -w 80 -s
	echo -e "\n\nAccess the redpanda application in a browser from the following URL: "
	echo -e "\e[0;31mhttp://$localip:8080\n\e[0m"
	read -p "Press enter to continue..."
}


create_rootfolder()
{
	real_user=$(whoami)
	cd /
	sudo mkdir $rootfolder
	sudo chown $real_user:$real_user $rootfolder
	sudo chmod 777 $rootfolder
	mkdir -p /$rootfolder/
	mkdir -p /$rootfolder/scripts
}

check_rootfolder_permissions()
{
	# Get the current user
    real_user=$(whoami)

	# Check if the rootfolder exists
	echo "Checking if $rootfoler exists"
    if [ -d "/$rootfolder" ]; then
        # Check if the directory is writable by the current user
        if [ -w "/$rootfolder" ]; then
            echo "/$rootfolder exists and is writable by $real_user"
        else
            echo "/$rootfolder exists but is not writable by $real_user, changing ownership"
            sudo chown $real_user:$real_user "/$rootfolder"
            # Verify the change was successful
            if [ -w "/$rootfolder" ]; then
                echo "Successfully changed ownership of /$rootfolder to $real_user"
            else
                echo "Failed to make /$rootfolder writable by $real_user"
                return 1
            fi
        fi
    else
        echo "/$rootfolder does not exist, creating it"
        create_rootfolder
    fi
}


base()
{
	real_user=$(whoami)


	os=`more /etc/os-release |grep PRETTY_NAME | cut -d  \" -f2 | cut -d " " -f1`
	if [ "$os" == "Ubuntu" ]; then 
			updates
			check_rootfolder_permissions

			sudo mkdir -p /etc/apt/keyrings
			sudo  NEEDRESTART_SUSPEND=1 apt-get install curl gnupg ca-certificates lsb-release --yes 
			sudo mkdir -p /etc/apt/keyrings
			curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg  
			
			sudo echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
			sudo apt-get update --allow-insecure-repositories
			sudo NEEDRESTART_SUSPEND=1 apt-get dist-upgrade --yes 
			
			version=` more /etc/os-release |grep VERSION_ID | cut -d \" -f 2`
			if  [ "$version" == "25.04" ]; then
	# Ubuntu 25.04
				sudo NEEDRESTART_SUSPEND=1 apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin python3.13-venv tmux python3-pip python3-venv kcat --yes 
	  	elif [ "$version" == "24.04" ]; then
	# Ubuntu 24.04
				sudo NEEDRESTART_SUSPEND=1 apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin python3.12-venv tmux python3-pip python3-venv kcat --yes 

	  	elif [ "$version" == "22.04" ]; then
	# Ubuntu 22.04
				sudo NEEDRESTART_SUSPEND=1 apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin python3.11-venv tmux python3-pip python3-venv kcat --yes 
	  	elif [ "$version" == "20.04" ]; then
	# Ubuntu 20.04
				sudo NEEDRESTART_SUSPEND=1 apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin python3.9-venv tmux python3-pip python3-venv kcat --yes 
	   	else
	  		sudo NEEDRESTART_SUSPEND=1 apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin python3.8-venv tmux python3-pip python3-venv kcat --yes 
	   	fi

			sudo usermod -aG docker $real_user
	
	elif [ "$os" == "Red" ]; then

			version=` more /etc/os-release |grep VERSION_ID | cut -d \" -f 2`
			if  [ "$version" == "9.5" ]; then
			# Redhat 9.5
	
				check_rootfolder_permissions
				sudo dnf -y install dnf-plugins-core
				sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
				sudo subscription-manager repos --enable codeready-builder-for-rhel-9-$(arch)-rpms
				sudo dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm -y
				sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin kcat
				sudo systemctl enable --now docker
				sudo yum install -y git
				sudo usermod -aG docker $real_user
				sudo dnf install -y python3.12
				sudo ln -sfn /usr/bin/python3.12 /usr/bin/python3
				

			else
			
				check_rootfolder_permissions
				sudo dnf -y install dnf-plugins-core
				sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
				sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin kcat
				sudo systemctl enable --now docker
				sudo yum install -y git
				sudo usermod -aG docker $real_user
				
				sudo dnf install -y python3.12
				sudo ln -sfn /usr/bin/python3.12 /usr/bin/python3
			
			fi
					
	fi 
	
}

broker()
{
	check_rootfolder_permissions
	cd /$rootfolder/
	git clone $brokergitlocation
	
	cd $brokerbasefolder
	clear 
	`git branch --all | cut -d "/" -f3 > gitversion.txt`
	echo -e "\e[0;31mEnter a line number to select a branch:\n\e[0m"

	git branch --all | cut -d "/" -f3 |grep -n ''

	read x
	brokerver=`sed "$x,1!d" gitversion.txt`
	git checkout  $brokerver
	echo $brokerver >installedversion.txt
	
	
	sleep 2
	cd $brokerbasefolder/
	/$rootfolder/$brokerbasefolder/setup
	
	
		echo -e "\e[0;31mMake sure you logout and then log back in to make use of the new enviroment variables.  \n\e[0m"
		echo -e "\e[0;31mOnce logged back in, change directory to: \e[1;33m/$rootfolder/$brokerbasefolder/ \e[0;31m\n\n"
		echo -e "Then run the following docker command:\n \e[1;33mdocker compose up -d \n\e[0m"			
		
}

brokerdockerup()
{		
		cd /$rootfolder/$brokerbasefolder/
	echo -e "Starting Broker containers\n"
					
		sleep 10 
				
		docker compose up --detach
		sleep 10 
		
				
				
}
		
elk()
{
	check_rootfolder_permissions
	cd /$rootfolder/
	git clone $elkgitlocation
	
	cd /$rootfolder/$elkbasefolder
	clear 
	`git branch --all | cut -d "/" -f3 > gitversion.txt`
	echo -e "\e[0;31mEnter a line number to select a branch:\n\e[0m"

	git branch --all | cut -d "/" -f3 |grep -n ''

	read x
	if [ "$x" == 1 ]; then
		elkver=`sed "$x,1!d" gitversion.txt | cut -d " " -f2`
	else 
		elkver=`sed "$x,1!d" gitversion.txt`	
	fi
	

	git checkout  $elkver
	echo $elkver >installedversion.txt
			
	cp docker-compose.yml docker-compose.yml.orig
	sed -i.bak  's/EF_OUTPUT_ELASTICSEARCH_ENABLE: '\''false'\''/EF_OUTPUT_ELASTICSEARCH_ENABLE: '\''true'\''/' docker-compose.yml
	localip=`hostname -I | cut -d " " -f1`

	sed -i.bak -r "s/EF_OUTPUT_ELASTICSEARCH_ADDRESSES: 'CHANGEME:9200'/EF_OUTPUT_ELASTICSEARCH_ADDRESSES: '$localip:9200'/" docker-compose.yml
	sed -i.bak -r "s/#EF_OUTPUT_ELASTICSEARCH_INDEX_PERIOD: 'daily'/EF_OUTPUT_ELASTICSEARCH_INDEX_PERIOD: 'daily'/" docker-compose.yml

	echo "Do you want to install a Elastiflow licence.
	
	Yes (y) and No (n) "
	echo "y or n "
	read x
  
  clear

	if  [ "$x" == "y" ]; then
		echo -e "\e[1;33mEnter the account ID:\n\e[0m"
		read a
		echo -e "\e[1;33mEnter the license key:\n\e[0m"
		read b
		
		sed -i.bak -r "s/#EF_ACCOUNT_ID: ''/EF_ACCOUNT_ID: '$a'/" docker-compose.yml
		sed -i.bak -r "s/#EF_FLOW_LICENSE_KEY: ''/EF_FLOW_LICENSE_KEY: '$b'/" docker-compose.yml

	else
  	echo "Continue"
	fi
	
	echo -e "\nJust to show you the changes we have made to the docker compose files \nIt was:\n EF_OUTPUT_ELASTICSEARCH_ENABLE: 'false'\n EF_OUTPUT_ELASTICSEARCH_ADDRESSES: 'CHANGEME:9200'\n\n Now:\n "
			
	more docker-compose.yml |egrep -i 'EF_OUTPUT_ELASTICSEARCH_ENABLE|EF_OUTPUT_ELASTICSEARCH_ADDRESSES|EF_ACCOUNT_ID|EF_FLOW_LICENSE_KEY'
	read -p "Press enter to continue"
	
				
	cd /$rootfolder/$elkbasefolder/
	echo $ELK >.env
	mkdir -p data/es_backups
	mkdir -p data/pensando_es
	mkdir -p data/elastiflow
	chmod -R 777 ./data
	sudo sysctl -w vm.max_map_count=262144
	echo vm.max_map_count=262144 | sudo tee -a /etc/sysctl.conf 

	echo -e "\e[0;31mGo and make a cup of Tea \nThis is going to take time to install and setup  \n\e[0m"
					
	
}

elksecurefile()
{
	
	cd /$rootfolder/$elkbasefolder/

	if grep -q "xpack.security.enabled=false" "docker-compose.yml"; then
		cp docker-compose.yml docker-compose.yml.presec	

		sed -i '/- cluster.initial_master_nodes=es01/d' docker-compose.yml
		sed -i '/- node.name=es01/d' docker-compose.yml
		sed -i.bak "s/- xpack.security.enabled=false/- discovery.type=single-node\n      - xpack.security.enabled=true\n      - ELASTIC_PASSWORD=changeme/" docker-compose.yml
		sed -i.bak "s/pensando-kibana/pensando-kibana\n    environment:\n      - ELASTICSEARCH_HOSTS=http:\/\/elasticsearch:9200\n      - ELASTICSEARCH_USERNAME=kibana_system\n      - ELASTICSEARCH_PASSWORD=kibana_system_pass\n      - xpack.security.enabled=true/" docker-compose.yml
		sed -i.bak  "s/pensando-logstash/pensando-logstash\n    environment:\n      - DICT_FILE= \{DICT_FILE\}/" docker-compose.yml
	else
	echo -e "\e[0;31mdocker compose with xpack already set up\e[0m\n check the config files"
	fi


	
}

elksecureup()
{
	export elkpass=$(< /dev/urandom tr -dc 'A-Za-z0-9' | head -c11)
	export kibpass=$(< /dev/urandom tr -dc 'A-Za-z0-9' | head -c11)
	cd logstash
	sed -i.bak 's/hosts[[:space:]]*=>[[:space:]]*\[ '\''elasticsearch'\'' \]/hosts    => [ '\''elasticsearch'\'' ]\n    user => '\"'elastic'\"' \n    password => '\"$elkpass\"' /' dss_syslog.conf

	cd ..
	sed -i.bak 's/changeme/'$elkpass'/' docker-compose.yml
	sed -i.bak 's/kibana_system_pass/'$kibpass'/' docker-compose.yml
	sleep 2
	docker compose up --detach --build
	echo -e "Waiting 100 seconds for services to start before configuration password...\n" | fold -w 80 -s
	sleep 20
	echo -e "80 seconds remaining...\n"
	sleep 20
	echo -e "60 seconds remaining...\n"
	sleep 20
	echo -e "40 seconds remaining...\n"
	sleep 20
	echo -e "20 seconds remaining...\n"
	sleep 15
	echo -e "5 seconds remaining...\n"
	sleep 1
	echo -e "4 seconds remaining...\n"
	sleep 1
	echo -e "3 seconds remaining...\n"
	sleep 1
	echo -e "2 seconds remaining...\n"
	sleep 1
	echo -e "1 second remaining...\n"
	sleep 1
	clear
	echo -e "Enter the following password into the password reset for Kibana_system :\e[0;31m $kibpass\e[0m"
	docker exec -it pensando-elasticsearch /usr/share/elasticsearch/bin/elasticsearch-reset-password -i -u kibana_system 
	curl -u elastic:$elkpass -X POST "http://localhost:9200/_security/user/admin?pretty" -H 'Content-Type: application/json' -d'{  "password" : "Pensando0$",  "roles" : [ "superuser" ],  "full_name" : "ELK Admin",  "email" : "admin@example.com"}'
	clear
	echo -e " Default username and password setup is: \n\e[0;31madmin - \"Pensando0$\"\n\e[0m"

}

secureelk()
{
	clear
	localip=`hostname -I | cut -d " " -f1`
	echo "Do you wish to enable ELK stack security for Kibana.
This is done as http only - if you wish to use https - refer to the ELK documentation"
	
	echo ""
	echo -e " This will take about 5 minutes"
	echo ""
	
		read -p "[Y]es or [N}o " p

		p=${p,,}

  	if  [[ "$p" == "y" ]]; then
  		cd /$rootfolder/$elkbasefolder/
			if grep -q "xpack.security.enabled=true" "docker-compose.yml"; then
				if grep -q "ELASTIC_PASSWORD=changeme" "docker-compose.yml"; then
    			docker compose down
					elksecureup
				else 
					echo -e "\e[0;31mdocker compose with xpack already configured \n\e[0m"

				fi 
			else
				docker compose down
				elksecurefile
				elksecureup
			fi
 
			elkdockerupnote

 		elif  [ "$p" == "n" ]; then
 			clear
 			elkdockerupnote
		fi
		 
}

elkdockerdown()
{
			cd /$rootfolder/$elkbasefolder/
			docker compose down
			
}

elkdockerup()
{		
		cd /$rootfolder/$elkbasefolder/
	echo -e "Starting ELK containers\n"
					
		sleep 10 
				
		docker compose up --detach
		
	echo -e "Waiting 100 seconds for services to start before configuration import...\n" | fold -w 80 -s
	sleep 20
	echo -e "80 seconds remaining...\n"
	sleep 20
	echo -e "60 seconds remaining...\n"
	sleep 20
	echo -e "40 seconds remaining...\n"
	sleep 20
	echo -e "20 seconds remaining...\n"
	sleep 15
	echo -e "5 seconds remaining...\n"
	sleep 1
	echo -e "4 seconds remaining...\n"
	sleep 1
	echo -e "3 seconds remaining...\n"
	sleep 1
	echo -e "2 seconds remaining...\n"
	sleep 1
	echo -e "1 second remaining...\n"
	sleep 1

	echo -e "Deploying collector configuration...\n"
	
		installedversion=`more installedversion.txt`
		
		if [ "$installedversion" == "aoscx_10.13" ]; then 
				
				curl -XPUT -H'Content-Type: application/json' 'http://localhost:9200/_index_template/pensando-fwlog?pretty' -d @./elasticsearch/pensando_fwlog_mapping.json
				echo -e "\e[1;33mImporting the Kibana dashboards and maintainence plans  \n\e[0m"
					
									
				sleep 10
				pensandodash=`ls -t ./kibana/pen* | head -1`
				elastiflowdash=`ls -t  ./kibana/kib* | head -1`
				curl -X POST "http://localhost:5601/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" -H "securitytenant: global" --form file=@$pensandodash
				curl -X POST "http://localhost:5601/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" -H "securitytenant: global" --form file=@$elastiflowdash
				
				
		elif [ "$installedversion" == "aoscx_10.13.1000" ]; then 
				
				curl -XPUT -H'Content-Type: application/json' 'http://localhost:9200/_index_template/pensando-fwlog?pretty' -d @./elasticsearch/pensando_fwlog_mapping.json

				echo -e "\e[1;33mImporting the Kibana dashboards and maintainence plans  \n\e[0m"
									
				sleep 10
				pensandodash=`ls -t ./kibana/pen* | head -1`
				elastiflowdash=`ls -t  ./kibana/kib* | head -1`
				curl -X POST "http://localhost:5601/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" -H "securitytenant: global" --form file=@$pensandodash
				curl -X POST "http://localhost:5601/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" -H "securitytenant: global" --form file=@$elastiflowdash
				
		elif [ "$installedversion" == "aoscx_10.14" ]; then 
				
				curl -XPUT -H'Content-Type: application/json' 'http://localhost:9200/_index_template/pensando-fwlog?pretty' -d @./elasticsearch/pensando_fwlog_mapping.json
				echo -e "\e[1;33mImporting the Kibana dashboards and maintainence plans  \n\e[0m"
									
				sleep 10
				pensandodash=`ls -t ./kibana/pen* | head -1`
				elastiflowdash=`ls -t  ./kibana/kib* | head -1`
				curl -X POST "http://localhost:5601/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" -H "securitytenant: global" --form file=@$pensandodash
				curl -X POST "http://localhost:5601/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" -H "securitytenant: global" --form file=@$elastiflowdash
				
				
		elif [ "$installedversion" == "aoscx_10.14.0001" ]; then 
				
				curl -XPUT -H'Content-Type: application/json' 'http://localhost:9200/_index_template/pensando-fwlog?pretty' -d @./elasticsearch/pensando_fwlog_mapping.json
				curl -XPUT -H'Content-Type: application/json' 'http://localhost:9200/_snapshot/my_fs_backup' -d @./elasticsearch/pensando_fs.json
				curl -XPUT -H'Content-Type: application/json' 'http://localhost:9200/_slm/policy/pensando' -d @./elasticsearch/pensando_slm.json
				curl -XPUT -H'Content-Type: application/json' 'http://localhost:9200/_ilm/policy/pensando' -d @./elasticsearch/pensando_ilm.json
				curl -XPUT -H'Content-Type: application/json' 'http://localhost:9200/_slm/policy/elastiflow' -d @./elasticsearch/elastiflow_slm.json
				curl -XPUT -H'Content-Type: application/json' 'http://localhost:9200/_ilm/policy/elastiflow' -d @./elasticsearch/elastiflow_ilm.json
				echo -e "\e[1;33mImporting the Kibana dashboards and maintainence plans  \n\e[0m"
									
				sleep 10
				pensandodash=`ls -t ./kibana/pen* | head -1`
				elastiflowdash=`ls -t  ./kibana/kib* | head -1`
				curl -X POST "http://localhost:5601/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" -H "securitytenant: global" --form file=@$pensandodash
				curl -X POST "http://localhost:5601/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" -H "securitytenant: global" --form file=@$elastiflowdash
				
		elif [ "$installedversion" == "aoscx_10.15" ]; then 
				
				curl -XPUT -H'Content-Type: application/json' 'http://localhost:9200/_index_template/pensando-fwlog?pretty' -d @./elasticsearch/pensando_fwlog_mapping.json
				curl -XPUT -H'Content-Type: application/json' 'http://localhost:9200/_snapshot/my_fs_backup' -d @./elasticsearch/pensando_fs.json
				curl -XPUT -H'Content-Type: application/json' 'http://localhost:9200/_slm/policy/pensando' -d @./elasticsearch/pensando_slm.json
				curl -XPUT -H'Content-Type: application/json' 'http://localhost:9200/_ilm/policy/pensando' -d @./elasticsearch/pensando_ilm.json
				curl -XPUT -H'Content-Type: application/json' 'http://localhost:9200/_slm/policy/elastiflow' -d @./elasticsearch/elastiflow_slm.json
				curl -XPUT -H'Content-Type: application/json' 'http://localhost:9200/_ilm/policy/elastiflow' -d @./elasticsearch/elastiflow_ilm.json
				echo -e "\e[1;33mImporting the Kibana dashboards and maintainence plans  \n\e[0m"
									
				sleep 10
				pensandodash=`ls -t ./kibana/pen* | head -1`
				elastiflowdash=`ls -t  ./kibana/kib* | head -1`
				curl -X POST "http://localhost:5601/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" -H "securitytenant: global" --form file=@$pensandodash
				curl -X POST "http://localhost:5601/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" -H "securitytenant: global" --form file=@$elastiflowdash
				
		elif [ "$installedversion" == "main" ]; then 
			
				curl -X DELETE 'http://localhost:9200/localhost:9200/_index_template/pensando-fwlog' 
				curl -X DELETE 'http://localhost:9200/_slm/policy/pensando'
				curl -X DELETE 'http://localhost:9200/_ilm/policy/pensando' 
				curl -X DELETE 'http://localhost:9200/_slm/policy/elastiflow'
				curl -X DELETE 'http://localhost:9200/_ilm/policy/elastiflow'
				
				
				curl -XPUT -H'Content-Type: application/json' 'http://localhost:9200/_ilm/policy/pensando_empty_delete' -d @./elasticsearch/policy/pensando_empty_delete.json
				curl -XPUT -H'Content-Type: application/json' 'http://localhost:9200/_ilm/policy/pensando_create_allow' -d @./elasticsearch/policy/pensando_create_allow.json
				curl -XPUT -H'Content-Type: application/json' 'http://localhost:9200/_ilm/policy/pensando_session_end' -d @./elasticsearch/policy/pensando_session_end.json
				curl -XPUT -H'Content-Type: application/json' 'http://localhost:9200/_ilm/policy/pensando_create_deny' -d @./elasticsearch/policy/pensando_create_deny.json
				curl -XPUT -H'Content-Type: application/json' 'http://localhost:9200/_ilm/policy/elastiflow' -d @./elasticsearch/policy/elastiflow.json
				
				curl -XPUT -H'Content-Type: application/json' 'http://localhost:9200/_index_template/pensando-fwlog-session-end?pretty' -d @./elasticsearch/template/pensando-fwlog-session-end.json
				curl -XPUT -H'Content-Type: application/json' 'http://localhost:9200/_index_template/pensando-fwlog-create-allow?pretty' -d @./elasticsearch/template/pensando-fwlog-create-allow.json
				curl -XPUT -H'Content-Type: application/json' 'http://localhost:9200/_index_template/pensando-fwlog-empty-delete?pretty' -d @./elasticsearch/template/pensando-fwlog-empty-delete.json
				curl -XPUT -H'Content-Type: application/json' 'http://localhost:9200/_index_template/pensando-fwlog-create-deny?pretty' -d @./elasticsearch/template/pensando-fwlog-create-deny.json
				
				echo -e "\e[1;33mImporting the Kibana dashboards and maintainence plans  \n\e[0m"
				
				sleep 10
				pensandodash=`ls -t ./kibana/pen* | head -1`
				elastiflowdash=`ls -t  ./kibana/kib* | head -1`
				curl -X POST "http://localhost:5601/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" -H "securitytenant: global" --form file=@$pensandodash
				curl -X POST "http://localhost:5601/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" -H "securitytenant: global" --form file=@$elastiflowdash
				
			
		elif [ "$installedversion" == "develop" ]; then 
			
				curl -X DELETE 'http://localhost:9200/localhost:9200/_index_template/pensando-fwlog' 
				curl -X DELETE 'http://localhost:9200/_slm/policy/pensando'
				curl -X DELETE 'http://localhost:9200/_ilm/policy/pensando' 
				curl -X DELETE 'http://localhost:9200/_slm/policy/elastiflow'
				curl -X DELETE 'http://localhost:9200/_ilm/policy/elastiflow'
				
				
				curl -XPUT -H'Content-Type: application/json' 'http://localhost:9200/_ilm/policy/pensando_empty_delete' -d @./elasticsearch/policy/pensando_empty_delete.json
				curl -XPUT -H'Content-Type: application/json' 'http://localhost:9200/_ilm/policy/pensando_create_allow' -d @./elasticsearch/policy/pensando_create_allow.json
				curl -XPUT -H'Content-Type: application/json' 'http://localhost:9200/_ilm/policy/pensando_session_end' -d @./elasticsearch/policy/pensando_session_end.json
				curl -XPUT -H'Content-Type: application/json' 'http://localhost:9200/_ilm/policy/pensando_create_deny' -d @./elasticsearch/policy/pensando_create_deny.json
				curl -XPUT -H'Content-Type: application/json' 'http://localhost:9200/_ilm/policy/elastiflow' -d @./elasticsearch/policy/elastiflow.json
				
				curl -XPUT -H'Content-Type: application/json' 'http://localhost:9200/_index_template/pensando-fwlog-session-end?pretty' -d @./elasticsearch/template/pensando-fwlog-session-end.json
				curl -XPUT -H'Content-Type: application/json' 'http://localhost:9200/_index_template/pensando-fwlog-create-allow?pretty' -d @./elasticsearch/template/pensando-fwlog-create-allow.json
				curl -XPUT -H'Content-Type: application/json' 'http://localhost:9200/_index_template/pensando-fwlog-empty-delete?pretty' -d @./elasticsearch/template/pensando-fwlog-empty-delete.json
				curl -XPUT -H'Content-Type: application/json' 'http://localhost:9200/_index_template/pensando-fwlog-create-deny?pretty' -d @./elasticsearch/template/pensando-fwlog-create-deny.json
				
				echo -e "\e[1;33mImporting the Kibana dashboards and maintainence plans  \n\e[0m"									

				sleep 10
				pensandodash=`ls -t ./kibana/pen* | head -1`
				elastiflowdash=`ls -t  ./kibana/kib* | head -1`
				curl -X POST "http://localhost:5601/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" -H "securitytenant: global" --form file=@$pensandodash
				curl -X POST "http://localhost:5601/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" -H "securitytenant: global" --form file=@$elastiflowdash

		fi 
		
		echo -e "\e[1;33mFinishing import  \n\e[0m"									
		
		sleep 20	
		
}

proxy()
{
	echo -e "\nSelect the type of proxy server:\n" | fold -w 80 -s
	read -p "[A]uthenticated, [N]on-authenticated, or anything else to return to main menu: " p

	p=${p,,}

  	if  [[ "$p" == "a" ]]; then
  	 	echo -e "Enter the proxy server IPv4 address or fully-qualified domain name.
 
Example: 

192.168.0.250 
or
yourproxyaddress.co.uk\n" | fold -w 80 -s
		read url
		
		read -p "Proxy server listening port: " port
		read -p "Proxy server username: " user
		read -p "Proxy server password: " pass
		
		### Needed for NO_PROXY environment variable
		noproxylocalip=`hostname -I | cut -d " " -f1`

		sudo rm -f -- /etc/apt/apt.conf
		sudo touch /etc/apt/apt.conf
		sudo chmod 777 /etc/apt/apt.conf
		echo "Acquire::http::Proxy \"http://$user:$pass@$url:$port\";" >>  /etc/apt/apt.conf
		
		git config --global http.proxy http://$user:$pass@p$url:$port

		### docker
		sudo mkdir -p /etc/systemd/system/docker.service.d
		sudo rm -f -- /etc/systemd/system/docker.service.d/proxy.conf
		sudo touch /etc/systemd/system/docker.service.d/proxy.conf
		sudo chmod 777 /etc/systemd/system/docker.service.d/proxy.conf
		echo "[Service]
		EnvironmentFile=/etc/system/default/docker
" >> /etc/systemd/system/docker.service.d/proxy.conf
		sudo mkdir -p /etc/system/default/
		sudo chmod 777 /etc/system/default/
		sudo rm -f -- /etc/system/default/docker
		sudo touch /etc/system/default/docker
		sudo chmod 777 /etc/system/default/docker
		echo "HTTP_PROXY='http%3A%2F%2F$user%3A$pass%40$url%3A$port%2F'
NO_PROXY=localhost,127.0.0.1,$noproxylocalip,::1
" >/etc/system/default/docker

#  		sudo systemctl daemon-reload
#  		sudo systemctl restart docker.service

		echo -e "Proxy server configuration complete, returning to main menu...\n"
	
	elif  [ "$p" == "n" ]; then
  	 	echo -e "Enter the proxy server IPv4 address or fully-qualified domain name.
 
Example: 

192.168.0.250 
or
yourproxyaddress.co.uk\n" | fold -w 80 -s

		read url
		
		read -p "Proxy server listening port: " port
		
		### cURL
		touch ~/.curlrc
		echo "proxy = $url:$port" >> ~/.curlrc

		sudo rm -f -- /etc/apt/apt.conf
		sudo touch /etc/apt/apt.conf
		sudo chmod 777 /etc/apt/apt.conf
		echo "Acquire::http::Proxy \"http://$url:$port\";" >> /etc/apt/apt.conf
		git config --global http.proxy http://$url:$port

		### docker
		sudo mkdir -p /etc/systemd/system/docker.service.d
		sudo rm -f -- /etc/systemd/system/docker.service.d/proxy.conf
		sudo touch /etc/systemd/system/docker.service.d/proxy.conf
		sudo chmod 777 /etc/systemd/system/docker.service.d/proxy.conf
		echo "[Service]
Environment=\"HTTP_PROXY=http://$url:$port\"
Environment=\"HTTPS_PROXY=http://$url:$port\"
Environment=\"NO_PROXY=localhost,127.0.0.1,$noproxylocalip,::1\"
" >> /etc/systemd/system/docker.service.d/proxy.conf
#  		sudo systemctl daemon-reload
#  		sudo systemctl restart docker.service

		echo -e "Proxy server configuration complete, returning to main menu...\n"

	else 
		echo "Returning to main menu..."
	fi
		
		
}

elkupgrade()
{
		cd /$rootfolder/$elkbasefolder/
			
		elkdockerdown
		
		git pull 
		
		if [ "$os" == "Ubuntu" ]; then 	
				updates
		elif [ "$os" == "Red" ]; then	
				updatesred
		fi 
		
		echo $ELK >.env
		
		cd /$rootfolder/$elkbasefolder/
		clear 
		git branch --all | cut -d "/" -f3 > gitversion.txt
		echo -e "Enter a line number to select a branch:\n"
		git branch --all | cut -d "/" -f3 |grep -n ''

		read x
		orig=`sed "1,1!d" gitversion.txt|cut -d ' ' -f 2`
		elkver=`sed "$x,1!d" gitversion.txt`

		sudo cp docker-compose.yml docker-compose.yml.$orig
		git checkout  $elkver --force
		git pull
 		localip=`hostname -I | cut -d " " -f1`

		echo $elkver >installedversion.txt
		
		olddocker=`ls -t docker*aos* |head -1`
		
		
		EFaccount=`more $olddocker |grep EF_ACCOUNT_ID| cut -d ":" -f 2|cut -d " " -f2  `
		EFLice=`more $olddocker |grep EF_FLOW_LICENSE_KEY| cut -d ":" -f 2|cut -d " " -f2  `
		sed -i.bak  's/EF_OUTPUT_ELASTICSEARCH_ENABLE: '\''false'\''/EF_OUTPUT_ELASTICSEARCH_ENABLE: '\''true'\''/' docker-compose.yml
		sed -i.bak -r "s/EF_OUTPUT_ELASTICSEARCH_ADDRESSES: 'CHANGEME:9200'/EF_OUTPUT_ELASTICSEARCH_ADDRESSES: '$localip:9200'/" docker-compose.yml
		sed -i.bak -r "s/#EF_ACCOUNT_ID: ''/EF_ACCOUNT_ID: $EFaccount/" docker-compose.yml
		sed -i.bak -r "s/#EF_FLOW_LICENSE_KEY: ''/EF_FLOW_LICENSE_KEY: $EFLice/" docker-compose.yml
		
	echo -e "The following changes have been made to the docker-compose.yml file:

Before:
		EF_OUTPUT_ELASTICSEARCH_ENABLE: 'false'
		EF_OUTPUT_ELASTICSEARCH_ADDRESSES: 'CHANGEME:9200'

After:
		EF_OUTPUT_ELASTICSEARCH_ENABLE: 'true'
		EF_OUTPUT_ELASTICSEARCH_ADDRESSES: '<YourIP>:9200'

		Running version:
		"
				
		more docker-compose.yml |egrep -i 'EF_OUTPUT_ELASTICSEARCH_ENABLE|EF_OUTPUT_ELASTICSEARCH_ADDRESSES|EF_ACCOUNT_ID|EF_FLOW_LICENSE_KEY'
		read -p "Press enter to continue"
		
	echo -e "\e[0;31mGo and make a cup of Tea \nThis is going to take time to install and setup  \n\e[0m"
}


testcode()
{
		echo " 
		Space for testing
					"
		#elksecurefile			
		secureelk 
		
}

while true ;
do
	echo -e "\e[0;31mPress Ctrl+C to exit at any time. \n\e[0m"

  echo -e "\n\e[1;33mThis following script will setup enviroment for either the Elastic or Broker install \nThe Broker is for 3rd party intergrations. The ELK stack is for CX10k Visualization. \n\e[0m
\e[0;31m The base install should be a clean install of Ubuntu with a static IP.\n\e[0m

Workflows provided by this script will: 

- Prepare the base system deployment by ensuring that the operating system is up to date and that \n  all prerequisites are installed
- Deploy and configure the ELK Stack components using Docker container instances and provided \n  configuration files 
- Enable username and password on ELK
- Deploy and configure the broker for Guardicore
- Update deployed ELK Stack components to the latest release

If this is your first time running this script on this system, select [B] to start the base system preparation workflow, which will end with a system reboot; once the system is up and running again, execute this script a second time from the local directory to continue with the deployment process.

NOTE: If a proxy server is required for this system to connect to the internet, select [P] to run the proxy server configuration workflow prior to starting base system preparation. \e[1;33mCurrently Ubuntu only and RHEL 9.5 \n\e[0m

Once the base system preparation and reboot have been completed: \nselect [E] to run the ELK Stack deployment workflow.\nselect [R] to run the Broker deployment workflow.\nselect [U] to run and ELK Stack upgrade workflow.\nselect [S] to setup username and password management for ELK\n

If the ELK Stack is already deployed and needs to be updated, select [U] to run the update workflow.\n" | fold -w 120 -s
	
	read -p "[B]ase system preparation, [E]LK Stack deployment, B[R]oker deployment, [U]pdate ELK, 
[S]ecure - Add username and password, [P]roxy configuration, or e[X]it: " x

  x=${x,,}
  
  clear

	if  [ $x == "b" ]; then
		echo -e "\nPress Ctrl+C to exit at any time.\n"
		echo -e "This workflow should only be run once; do not run it again unless you have previously cancelled it before completion.\n" | fold -w 80 -s
		read -p "Enter 'C' to continue: " x
		
		x=${x,,}
		clear
		while [ $x ==  "c" ] ;
		do
	    	basenote
		  	base 
		  	rebootserver
		  	x="done"
	  done

	elif [  $x == "e" ]; then
		echo -e "\nPress Ctrl+C to exit at any time.\n"
		echo -e "This workflow should only be run once; running it additional times	will result in restoring the ELK Stack to default settings and removal of all stored data.\n" | fold -w 80 -s
		read -p "Enter 'C' to continue: " x
		x=${x,,}
		while [[ "$x" ==  "c" ]] ;
		do
			elknote
			elk 
			elkdockerup
			secureelk
			x="done"
			exit 0
		done
  
	elif [[ "$x" == "p" ]]; then
		echo -e "\nPress Ctrl+C to exit at any time.\n"
		echo -e "This workflow should normally only be run once; it should only	need to be run again if the ELK Stack components need to be updated or redeployed and the proxy server configuration has changed since the original deployment.\n" | fold -w 80 -s
		read -p "Enter 'C' to continue: " x
		x=${x,,}

			##clear
		while [  "$x" ==   "c" ] ;
		do
			proxy 
			x="done"
		done
				

	elif [[ "$x" ==  "u" ]]; then
		##clear
		echo -e "\nPress Ctrl+C to exit at any time.\n"
		echo -e "This workflow updates base system software packages and allows selection of an updated version of the ELK Stack environment from the GitHub repository.\n" | fold -w 80 -s
		read -p "Enter 'C' to continue: " x
		x=${x,,}

		while [  "$x" ==   "c" ] ;
		do
			elkupgrade
			elkdockerup
			elkdockerupnote
			#rebootserver
			x="done"
		done

	elif [  "$x" ==  "r" ]; then
		echo -e "\nPress Ctrl+C to exit at any time.\n"
		echo -e "This workflow should only be run once; running it additional times will result in restoring the Broker Stack to default settings and removal of all stored data.\n" | fold -w 80 -s
		read -p "Enter 'C' to continue: " x
		x=${x,,}
		while [[ "$x" ==  "c" ]] ;
		do
			brokernote
			broker
			x="done"
			exit 0
		done

							
	elif [  "$x" ==  "s" ]; then
		secureelk

							
	elif [  "$x" ==  "t" ]; then
		testcode
				  

	elif [ "$x" ==  "x" ]; then
		echo -e "\nExiting...\n"
		exit 0


	else
		echo -e "\nInvalid option, try again...\n"
	fi

done