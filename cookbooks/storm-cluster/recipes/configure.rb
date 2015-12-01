#
# Cookbook Name:: storm
# Recipe:: configure
#
# Copyright 2015, XLAB d.o.o.
#
# All rights reserved - Do Not Redistribute
#
# This recipe should be called when the application is being
# configured, i.e., when the related components (zookeeper, 
# any other Storm nodes) have been created, but not yet connected.

require 'json'

storm_user = node['storm']['user']
storm_package_name = node['storm']['package']
storm_version = node['storm']['version']
storm_remote_name = "#{node['storm']['download_url']}#{node['storm']['download_dir']}"
install_dir = node['storm']['install_dir']

storm_yaml = node['storm']['storm_yaml'].to_hash.dup

zookeepers_hash = 
	node["cloudify"]["runtime_properties"]["zookeeper_servers"]
zookeeper_addresses = zookeepers_hash.values

nimbus = 
	node["cloudify"]["runtime_properties"]["nimbus_server_address"]

storm_yaml["storm.zookeeper.servers"] = zookeeper_addresses
storm_yaml["nimbus.host"] = nimbus

template "#{install_dir}/#{storm_version}/conf/storm.yaml" do
  source 'storm.yaml.erb'
  mode '0644'
  owner storm_user
  group storm_user
  variables(
    'storm_yaml' => JSON.parse(storm_yaml.to_json)
  )
end