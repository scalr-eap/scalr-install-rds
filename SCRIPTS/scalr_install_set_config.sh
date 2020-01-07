#!/bin/bash

# take the template file and substitute the IPs

exec 1>/var/tmp/$(basename $0).log

exec 2>&1

abort () {
  echo "ERROR: Failed with $1 executing '$2' @ line $3"
  exit $1
}

trap 'abort $? "$STEP" $LINENO' ERR


PROXY_1_PUB=$1
shift
PROXY_1_PRIV=$1
shift
PROXY_2_PRIV=$1
shift
WORKER=$1
shift
INFLUXDB=$1
shift
DB_ENDPOINT=$1

STEP="Create config with cat"

cat << ! > /var/tmp/scalr-server.rb
########################################################################################
# IMPORTANT: This is NOT a substitute for documentation. Make sure that you understand #
# the configuration parameters you use in your configuration file.                     #
########################################################################################

##########################
# Topology Configuration #
##########################
# You can use IPs for the below as well, but hostnames are preferable.
ENDPOINT = '$PROXY_1_PUB'
MASTER_MYSQL_SERVER_HOST = '$DB_ENDPOINT'
APP_SERVER_1 = '$PROXY_1_PRIV'
APP_SERVER_2 = '$PROXY_2_PRIV'
WORKER_SERVER = '$WORKER'
INFLUXDB_SERVER = '$INFLUXDB'
MEMCACHED_PORT = "11211"

####################
 # External Routing #
####################
enable_all false

proto = 'http'  # Set up the SSL settings and this to 'https' to use HTTPS

routing[:endpoint_scheme] = proto
routing[:endpoint_host] = ENDPOINT

routing[:graphics_scheme] = proto
routing[:graphics_host] = ENDPOINT

routing[:plotter_scheme] = proto
routing[:plotter_host] = ENDPOINT
routing[:plotter_port] = if proto == 'http' then 80 else 443 end

####################
# Internal Routing #
####################

## In the event of a failover event, change this to SLAVE_MYSQL_SERVER_HOST
app[:mysql_scalr_host] = MASTER_MYSQL_SERVER_HOST
app[:mysql_scalr_port] = 3306

## In the event of a failover event, change this to SLAVE_MYSQL_SERVER_HOST
app[:mysql_analytics_host] = MASTER_MYSQL_SERVER_HOST
app[:mysql_analytics_port] = 3306

# Memcached Servers
app[:memcached_servers] = [APP_SERVER_1 + ':' + MEMCACHED_PORT, APP_SERVER_2 + ':' + MEMCACHED_PORT]

# Look for the app and graphics locally as well
proxy[:app_upstreams] = ['127.0.0.1:6000']
proxy[:graphics_upstreams] = ['0.0.0.0:6100']
proxy[:plotter_upstreams]  = ['0.0.0.0:6200']

# Bind the proxy publicly
proxy[:bind_host] = '0.0.0.0'

# But bind locally, since it'll go through the proxy
web[:app_bind_host] = '127.0.0.1'
web[:app_bind_port] = 6000

web[:graphics_bind_host] = '0.0.0.0'
web[:graphics_bind_port] = 6100

service[:plotter_bind_host] = '0.0.0.0'
service[:plotter_bind_port] = 6200

# Bind MySQL publicly, because it'll need to be accessed by the app & worker
mysql[:bind_host] = '0.0.0.0'
mysql[:bind_port] = 3306

memcached[:bind_host] = '0.0.0.0'
memcached[:bind_port] = 11211

# Scalr Web/AMQP Host
app[:influxdb_host] = INFLUXDB_SERVER
influxdb[:http_bind_host] = '0.0.0.0'

app[:rabbitmq_host] = WORKER_SERVER
rabbitmq[:bind_host] = '0.0.0.0'
rabbitmq[:mgmt_bind_host] = '0.0.0.0'
proxy[:rabbitmq_upstreams] = [WORKER_SERVER]

repos[:enable] = true

app[:configuration] = {
  :scalr => {
      :ui => {
         :login_warning => "WELCOME TO SCALR - INSTALLED by Terraform  <p>This is a multi-server Scalr installation entirely built by Terraform using Scalr as a remote Backend</p> A single template has done the following:<ul><li>Deployed 2 Proxies, Worker, RDS based MySQL DB, Influxdb servers and installed Scalr</li> <li>Backed by EBS volumes configured to recommnded sizes</li> <li> Configured a ELB on the proxies</li> <li>Built the config based on the IP's and ELB dns name returned by TF</li> <li>Deployed the config, license and local files to all servers</li> <li>Enabled MySQL replication</li><li>Run reconfigure</li></ul>"
      },
      :system => {
        :server_terminate_timeout => 'auto',
        :api => {
                :enabled => true,
                :allowed_origins => '*,https://api-explorer.scalr.com'
       }
    },
    :scalarizr_update => {
      :mode => "solo",
      :default_repo => "latest",
      :repos => {
        "latest" => {
          :rpm_repo_url => "http://"+ENDPOINT+"/repos/rpm/latest/rhel/\$releasever/\$basearch",
          :suse_repo_url => "http://"+ENDPOINT+"/repos/rpm/latest/suse/\$releasever/\$basearch",
          :deb_repo_url => "http://"+ENDPOINT+"/repos/apt-plain/latest /",
          :win_repo_url => "http://"+ENDPOINT+"/repos/win/latest",
        },
      },
    },
  },
}

!
