#
# Cookbook Name:: uc4-agent
# Recipe:: agent
#
# Copyright 2013, UC4 Software
#
# All rights reserved - Do Not Redistribute
#

# Install UC4 Agent

cache_path = Chef::Config[:file_cache_path]

arch = node['kernel']['machine']

agent_path = node['uc4agent']['path']

# set the agent name to the hostname
node.default['uc4agent']['agentname'] = node['hostname']

if (arch =~ /i(.{1})86/)
  # x86 package
  package_name = 'agentx86'
  config_files = { :windows => 'ucxjwi3.ini', :linux => 'ucxjli3.ini'}
elsif (arch =~ /x(.*)64/)
  package_name = 'agentx64'
  config_files = { :windows => 'ucxjwx6.ini', :linux => 'ucxjlx6.ini'}
elsif (arch =~ /ia(.*)64/)
  package_name = 'agentia64'
  config_files = { :windows => 'ucxjwi6.ini', :linux => 'ucxjli6.ini'}
else
  # log message: No support for this architecture
  #return
  Chef::Application.fatal!("No support for this architecture: #{arch}")
end

if ['debian', 'rhel', 'fedora', 'freebsd', 'arch', 'suse'].include?(node['platform_family'])
  
  # copy agent archive to temp location
  cookbook_file "#{cache_path}/uc4agent.tar.gz" do
    source "#{package_name}.tar.gz"
    mode 00755
    action :create_if_missing
  end

  directory node['uc4agent']['path'] do
    owner 'root'
    group 'root'
    mode 00755
    recursive true
    action :create
  end

  execute "extract" do
    cwd cache_path
    command "tar xzvf uc4agent.tar.gz -C #{agent_path}"
    action :run
    not_if { ::File.exists?("#{agent_path}/bin/ucx.msl") }
  end

  execute "change-owner" do
    command "chown -R root:root #{agent_path}"
    action :run
  end

  template "#{agent_path}/bin/#{config_files[:linux]}" do
    source "#{config_files[:linux]}.erb"
    mode 0644
  end

  # copy ARATools.jar to agent bin
end

# For Windows node
if platform?("windows")  
  cookbook_file "#{cache_path}\\uc4agent.zip" do
    source "#{package_name}.zip"
    action :create_if_missing
  end
        
  directory node['uc4agent']['path'] do
    recursive true
    action :create
  end
  
  # Extract service manager to destination
  windows_zipfile node['uc4agent']['path'] do 
    source "#{cache_path}\\uc4agent.zip"
    action :unzip
    not_if {::File.exists?("#{agent_path}\\bin\\uc.msl")}
  end

  template "#{agent_path}\\bin\\#{config_files[:windows]}" do
    source "#{config_files[:windows]}.erb"
  end

  # copy ARATools.jar to agent bin

end
