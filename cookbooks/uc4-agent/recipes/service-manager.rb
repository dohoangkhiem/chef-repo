#
# Cookbook Name:: uc4-agent
# Recipe:: service-manager
#
# Copyright 2013, UC4 Software
#
# All rights reserved - Do Not Redistribute
#

include_recipe "uc4-agent::agent"

# Install UC4 Service Manager

cache_path = Chef::Config[:file_cache_path]

arch = node['kernel']['machine']

smgr_path = node['uc4servicemanager']['path']

if (arch =~ /i(.{1})86/)
  pkg_suffix = 'x86'
  file_suffix = 'i3'
elsif (arch =~ /x(.*)64/)
  pkg_suffix = 'x64'
  file_suffix = 'x6'
elsif (arch =~ /ia(.*)64/)
  pkg_suffix = 'ia64'
  file_suffix = 'i6'
else 
  raise "No support for this architecture: #{arch}"
end

if ['debian', 'rhel', 'fedora', 'freebsd', 'arch', 'suse'].include?(node['platform_family'])
  
  # copy service manager archive to temp location
  cookbook_file "#{cache_path}/ucsmgr.tar.gz" do
    source "ucsmgr#{pkg_suffix}.tar.gz"
    mode 00755
    action :create_if_missing
  end

  directory node['uc4servicemanager']['path'] do
    owner 'root'
    group 'root'
    mode 00755
    recursive true
    action :create
  end

  execute "extract" do
    cwd cache_path
    command "tar xzvf ucsmgr.tar.gz -C #{smgr_path}"
    action :run
    not_if { ::File.exists?("#{smgr_path}/bin/ucybsmgr") }
  end

  execute "change-owner" do
    command "chown -R root:root #{smgr_path}/*"
    action :run
  end

  template "#{smgr_path}/bin/ucybsmgr.ini" do
    source "ucybsmgr.ini.erb"
    mode 0644
    #notifies :run, 'execute[start-service]', :immediately
  end

  # TODO: Templating SMC and SMD files
  

  # start UC4 daemon
  execute "start-service" do
    command "#{smgr_path}/bin/ucybsmgr"
    action :run
  end

end

# For Windows node
if platform?("windows")  
  cookbook_file "#{cache_path}\\ucsmgr.zip" do
    source "ucsmgr#{pkg_suffix}.zip"
    action :create_if_missing
  end

  directory node['uc4servicemanager']['path'] do
    recursive true
    action :create
  end
  
  # Extract service manager to destination
  windows_zipfile node['uc4servicemanager']['path'] do 
    source "#{cache_path}\\ucsmgr.zip"
    action :unzip
    not_if {::File.exists?("#{smgr_path}\\bin\\ucybsmgr.exe")}
  end

  template "#{smgr_path}\\bin\\ucybsmgr.ini" do
    source "ucybsmgr.ini.erb"
  end

  # TODO: Templating SMD file
  template node['uc4servicemanager']['smd_file'] do
    source "UC4.smd.erb"
    variables(
      :executable_file => "ucxjw#{file_suffix}.exe",
      :ini_file => "ucxjw#{file_suffix}.ini"
    )
  end

  phrase = node['uc4servicemanager']['phrase']
  # execute service manager to install to Windows Service
  windows_batch "install-service" do
    code "#{smgr_path}\\bin\\ucybsmgr.exe -install #{phrase} -i#{smgr_path}\\bin\\ucybsmgr.ini"
  end
 
  # start UC4 service
  service "UC4.ServiceManager.#{phrase}" do
    action [:enable, :start]
  end

  # copy service manager dialog
  cookbook_file "#{cache_path}\\ucsmd.zip" do
    source "ucsmd#{pkg_suffix}.zip"
    action :create_if_missing
  end

  # extract service manager dialog
  windows_zipfile node['uc4servicemanager']['path_dialog'] do 
    source "#{cache_path}\\ucsmd.zip"
    action :unzip
    not_if {::File.exists?(::File.join(node['uc4servicemanager']['path_dialog'], "bin", "UCYBSMCl.exe"))}
  end

  hostname = node['hostname']
  # invoke UCYBSMCl to start UC4 Agent
  windows_batch "start-agent" do
    cwd node['uc4servicemanager']['path_dialog'] + "\\bin"
    code "UCYBSMCl.exe -c START_PROCESS -h #{hostname} -n #{phrase} -s UC4-Agent"
    action :run
  end

end
