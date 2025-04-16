# pensando-tools
Installer tools used by the AMD Pensando sales team for PoC/Demo installations.


This repository is a resource to be used for deploying and maintaining an instance of the Elastic (or ELK) Stack or Broker 
ELK for collecting, monitoring, and analyzing data from HPE Aruba Networking CX switches within your network environment.
Broker for managing the parsing of data to thrid party tools like Guardicore (first image).

This application currently supports Ubuntu 20.04, 22.04, or 24.04 (though it may work with other versions as well).

A deployment script is provided as part of this repository, which performs the following tasks:

1. Prepares the base operating system by applying available updates and installing prerequisites
2. Downloads and deploys the ELK Stack components as Docker containers
3. Deploys configuration files to enable collection of flow records, firewall logs, and event logs from CX switches
4. Downloads and deploys the Broker Stack components as Docker containers
4. Updates existing deployments to newer versions

Optionally, a proxy server can be configured using the deployment script to enable base system preparation and application deployment through an HTTP web proxy.

## Deploying the ELK Stack platform

To deploy the ELK Stack using this repository, first ensure that you are running an Ubuntu server instance (20.04, 22.04, or 24.04). If the installation procedure will be done remotely, ensure that OpenSSH is installed and functioning normally.

If the deployment target requires a proxy server for internet connectivity and one was not already configured during operating system installation, set the **http_proxy** and **https_proxy** environment variables to the proxy server IP address or fully-qualified domain name using the following commands:

    export http_proxy=http://[ip-or-hostname]:[listening-port]/
    export https_proxy=http://[ip-or-hostname]:[listening-port]/

Run the installation script using the following command:


    wget -O ./Install_pensando_tools.sh https://raw.githubusercontent.com/amd/pensando-tools/refs/heads/main/Install_pensando_tools.sh && chmod +x ./Install_pensando_tools.sh && ./Install_pensando_tools.sh

If proxy server configuration is required, select option **"p"** when prompted, and follow the instructions.

To start base system preparation select option **"b"**. This will:

1. Update installed operating system software packages to the latest available versions
2. Install all prerequisites and dependencies for Docker and the ELK Stack components

This process will take several minutes, during which there may be little to no console output or visible activity; do not interrupt the script, as this may leave the system in an unexpected state. Once base system preparation is complete, the system will automatically reboot.

Once the system is back up and running, run the script again from local storage:

    ./Install_pensando_tools.sh

When prompted, select option **"e"** to start the ELK Stack deployment and configuration workflow. The script will connect to this GitHub repository and present a list of branches for each major revision to the application based on AOS-CX software releases; enter the line number for the desired application version.

If you have an ElastiFlow license key to be used for the deployed application, enter the information when prompted.

The script will then begin the deployment process for the ELK Stack components, downloading and deploying each component (Elasticsearch, Logstash, Kibana, and the ElastiFlow flow collector) as Docker containers, then applying configuration files to enable data collection and display for CX switches.


## Deploying the Broker Stack platform

To deploy the Broker Stack using this repository, first ensure that you are running an Ubuntu server instance (20.04, 22.04, or 24.04). If the installation procedure will be done remotely, ensure that OpenSSH is installed and functioning normally.

If the deployment target requires a proxy server for internet connectivity and one was not already configured during operating system installation, set the **http_proxy** and **https_proxy** environment variables to the proxy server IP address or fully-qualified domain name using the following commands:

    export http_proxy=http://[ip-or-hostname]:[listening-port]/
    export https_proxy=http://[ip-or-hostname]:[listening-port]/

Run the installation script using the following command:


    wget -O ./Install_pensando_tools.sh https://raw.githubusercontent.com/amd/pensando-tools/refs/heads/main/Install_pensando_tools.sh && chmod +x ./Install_pensando_tools.sh && ./Install_pensando_tools.sh
    
If proxy server configuration is required, select option **"p"** when prompted, and follow the instructions.

To start base system preparation select option **"b"**. This will:

1. Update installed operating system software packages to the latest available versions
2. Install all prerequisites and dependencies for Docker and the ELK Stack components

This process will take several minutes, during which there may be little to no console output or visible activity; do not interrupt the script, as this may leave the system in an unexpected state. Once base system preparation is complete, the system will automatically reboot.

Once the system is back up and running, run the script again from local storage:

    ./Install_pensando_tools.sh

When prompted, select option **"r"** to start the Broker Stack deployment and configuration workflow. The script will connect to this GitHub repository and pull the latest main brach of the broker.

It will prompt you for connection details for your PSM enviroment, and provide notes on the bringing up of the containers.

**" You must log out and log back in to bring up the docker enviroment to use the enviromental variables created during install"**

### Using crontab for cookie renew
As the PSM api cookie is only valid for 7 days, we need to renew the cookie that the broker users.
The easiest way to do this is to install into the user crontab space the renew script to be called every 5 days.

     crontab -e

Add the following line at the end. 

     * * */5 * * ~/.local/bin/renew_psm_cookie.sh >/dev/null 2>&1



## Updating the ELK Stack platform

To update a deployed instance of the HPE Aruba Networking CX ELK Stack platform, run the local copy of the install script (or, optionally, redownload the script using the command above):

    ./Install_pensando_tools.sh

When prompted, select the **"u"** option to start the update process. This will:

1. Stop all running Docker containers
2. Update base operating system software packages to the latest available versions
3. Connect to this GitHub repository and pull the list of available branches
4. Prompt you for the desired platform version to upgrade to

Once the new version has been selected, the script will:

1. Download the latest versions of the Docker containers for each ELK Stack component
2. Start all ELK Stack Docker containers
3. Deploy collector and dashboard configuration files to the running containers

## Platform support

For support or feedback on the installation script or any other components of this repository, please [file an issue](https://github.com/amd/pensando-tools/issues).


## Disclaimer

The script provided by AMD is open-source and is governed by its applicable licensing terms. AMD is not responsible for any issues arising from the use of this script.

Please note that the software components installed and configured by this script, including but not limited to Ubuntu Linux, Redpanda, Kafka, Elasticsearch, Logstash, Kibana, and ElastiFlow, are also governed by their respective licensing terms and conditions. It is the responsibility of the end user to review, understand, and comply with these licensing agreements. HPE Aruba Networking assumes no responsibility for any licensing obligations or issues that may arise from the use of these software components.

By using this script, you acknowledge and agree that you are solely responsible for ensuring compliance with all applicable licensing requirements referred above.
