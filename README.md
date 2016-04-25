Getperf
=======

About Getperf
-------------

The Getperf is software that has the following features in the development framework of the system monitoring .

* It will support the PDCA cycle of system monitoring.
* With **Plan** phase of the initial construction, selects the standard template , to quickly build a monitoring system .
* In the case of **Check** phase , extend system-specific monitoring metrics and graph layout , you can customize the monitoring site to suit the system operation efficiently.
* Initial learning cost is high because it is a script-based customizing.
* you can automate the registration on the basis of the monitoring rules that you created , when you add new server.
* The basic flow is a figure below, the agent executes the command, then the server collect data and regist monitoring software (Cacti, Zabbix).

![PDCA](docs/image/pdca_en.png)

The system monitoring operation has the following two applications, using open source suitable for each, and then integrate the system monitoring.

|              | Event monitoring (Zabbix)                | Trend monitoring (Cacti)                      |
| ------------ | ---------------------------------------- | --------------------------------------------- |
| Applications | 1st escalation in the case of fault      | Secondary analysis of failure                 |
|              | Focus on known problems (routine tasks)  | Focus on unknown problem (atypical work)      |
| Approach     | Alert e-mail notification                | Monitoring of graph                           |
|              | Exhaustive, comprehensive approach       | Heuristic, refinement after system is Go Live |
| Needs        | Need a firmly and robust mechanism       | Need a flexible mechanism                     |
|              | Need a Immediacy, reliability            | Need a ad-hoc analysis of large data          |

Install
=======

You wrote the installation instructions for CentOS 6.x environment. Please refer to the [installation](03_Installation/index.html).

Notes
-----

Installation of the server has a strong dependence in the root,　It could be adversely affected the existing environment. We strongly recommend the installation of a clear installation environment OS.

Preparation
-----------

* In an intranet environment becomes necessary Proxy setting during the external connection with yum command.
* Installation user need to run sudo privileges. Please refer to [preparation](03_Installation/01_Preparation.html).

Package Installation
---------------

Install the basic package

    sudo -E yum -y groupinstall "Development Tools"
    sudo -E yum -y install kernel-devel kernel-headers
    sudo -E yum -y install libssh2-devel expat expat-devel libxml2-devel
    sudo -E yum -y install perl-XML-Parser perl-XML-Simple perl-Crypt-SSLeay perl-Net-SSH2
    sudo -E yum -y update

Download the Getperf module ※ provisional public version

    (Download 'getperf.tar.gz' from the provisional site)
    cd $ HOME
    tar xvf getperf.tar.gz
    cd getperf

Install the cpanm

    source script/profile.sh
    echo source $ GETPERF_HOME/script/profile.sh >> ~/.bash_profile
    sudo -E yum -y install perl-devel
    curl -L http://cpanmin.us | perl - --sudo App::cpanminus
    cd $ GETPERF_HOME
    sudo -E cpanm --installdeps .

Server Installation
-----------

To complete the installation by using software configuration management tool [Rex] the (http://www.rexify.org/)

Create a configuration file

    cd $ GETPERF_HOME
    perl script/cre_config.pl

Create the SSH key for local access of Git repositories

	rex install_ssh_key

Install the Web Service

    sudo -E rex install_package
    sudo -E rex install_sumupctl
    rex create_ca
    rex server_cert
    rex prepare_apache
    rex prepare_tomcat
    rex prepare_tomcat_lib
    rex prepare_ws
    sudo -E rex svc_auto
    rex svc_start

Set the MySQL and Cacti

    rex prepare_mysql
    rex prepare_composer
    rex prepare_cacti

Install the Zabbix

    rex prepare_zabbix

Register the periodic update script of SSL client certificate to Cron

    sudo rex run_client_cert_update

Agent compile
-------------

Compile the agent source in the monitoring server CentOS.
Create the download for the Web page, Eegister the source module of the agent.

    sudo -E rex prepare_agent_download_site
    rex make_agent_src

In a Web browser, Download the source module "getperf-2.x-Buildx-source.zip"

    wget http: //{server address}/docs/agent/getperf-2.x-Build6-source.zip

Compile to extract the source module

    unzip getperf-2.x-Build4-source.zip
    cd getperf-agent
    ./configure
    make

Install the agent

    perl deploy.pl

Other platforms compile, such as Windows, please refer to [compile on each platform](03_Installation/10_AgentCompile.html # id5).

How to use
==========

Site initialization
-------------------

To build the site under the specified directory. Here you create a site called 'site1'.

    cd (a directory)
    initsite.pl site1

It will output the message such as Site key, access key, and Cacti site URL. Site key, access key use in the setup of the agent. So please make a note. Go to open the URL and Cacti site. And log in as admin/admin.

Agent Setup
-----------

Here are the set-up procedure of the Linux environment. For Windows, please refer to the [Windows monitoring](04_Tutorial/03_WindowsResourceMonitoring.html).
Go to the ptune/bin of the installed agent, and run the setup.

    cd $ HOME/ptune/bin
    ./getperfctl setup

You will need to enter the access key that was issued by the site initialization at the time of the agent authentication. After the agent authentication, and an update of the SSL certificate.
Once the setup is complete, start the agent.

    ./getperfctl start

Create the automatic startup script to /etc/init.d/.

    sudo perl install.pl --all

Graph registration
------------------

Go to the site directory.

    cd (site storage directory)/site1

Site directory structure will be the following, it will be used in customization of the monitoring site, such as a graph definition and data aggregation.

* lib: aggregation script of collecting data, the metric of the storage directory, such as graph registration definition.
* analysis: collecting data deployment directory from the agent. Collected data is stored in the date directory order.
* summary: summary results of the save directory of collecting data.
* storage: time-series database RRDTool of storage directory.
* node: metric definition file. ** {Domain}/{node}/will file the form {metric} .json **.

Make a chart registration on the basis of the definition files that are generated under the node directory.

    cacti-cli node/Linux/{agent name}/

After the execution, and access to the Cacti site, make sure that the resource graph, such as CPU utilization rate of the target agent has been created.
Customizing the graph layout, please refer to the [Cacti graph registration](07_CactiGraphRegistration/index.html).

Refference
===========

1. [gSOAP](http://www.cs.fsu.edu/~engelen/soap.html)
2. [Apache Axis2/Java](http://axis.apache.org/axis2/java/core/index.html)
3. [Rex](http://www.rexify.org/)
4. [RRDTool](http://oss.oetiker.ch/rrdtool/)
5. [Cacti](http://www.cacti.net/)
6. [Zabbix](http://www.zabbix.com)

AUTHOR
======

Minoru Furusawa <minoru.furusawa@toshiba.co.jp>

COPYRIGHT
=========

Copyright 2014-2016, Minoru Furusawa, Toshiba corporation.

LICENSE
=======

This program is released under [GNU General Public License, version 2](http://www.gnu.org/licenses/gpl-2.0.html).
