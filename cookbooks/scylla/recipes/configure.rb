# Cookbook Name:: scylla
# Recipe:: configure
#
# Copyright 2016, XLAB d.o.o.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Obtain host ip
ip = if node['cloudify']['runtime_properties'].key?('host_ip')
       node['cloudify']['runtime_properties']['host_ip']
     else
       node['ipaddress']
     end

# If no seeds are present, we are the seed
seeds = if node['cloudify']['runtime_properties'].key?('seeds')
          node['cloudify']['runtime_properties']['seeds'].join(',')
        else
          ip
        end

# Configure scylla
scylla_conf = node['scylla']['yaml'].to_hash
scylla_conf.merge!(node['cloudify']['properties']['configuration'].to_hash)

# Next three settings cannot be overriden by user
scylla_conf['listen_address'] = ip
scylla_conf['rpc_address'] = '0.0.0.0'
scylla_conf['broadcast_rpc_address'] = ip
scylla_conf['seed_provider'] = [{
  'class_name' => 'org.apache.cassandra.locator.SimpleSeedProvider',
  'parameters' => [{
    'seeds' => seeds
  }]
}]

file '/etc/scylla/scylla.yaml' do
  mode 0644
  action :create
  content scylla_conf.to_yaml
end

template '/etc/scylla/cassandra-rackdc.properties' do
  source 'cassandra-rackdc.properties.erb'
  owner 'root'
  group 'root'
  mode 0755
  variables rack: 'rack1', dc: 'dc1'
end

bash 'Configure system for ScyllaDB' do
  code <<-EOF
    scylla_setup --setup-nic --no-raid-setup --no-coredump-setup \
      --no-node-exporter --nic $(ls /sys/class/net | grep -v lo | head -n1)
  EOF
end
