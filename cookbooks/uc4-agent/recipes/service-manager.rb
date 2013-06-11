#
# Cookbook Name:: uc4-agent
# Recipe:: service-manager
#
# Copyright 2013, UC4 Software
#
# All rights reserved - Do Not Redistribute
#

# Install UC4 Service Manager

cache_path = Chef::Config[:file_cache_path]

arch = node['kernel']['machine']

smgr_path = node['uc4servicemanager']['path']

if (arch =~ /i(.{1})86/)
  # x86 package
  package_name = 'ucsmgrx86'
elsif (arch =~ /x(.*)64/)
  package_name = 'ucsmgrx64'
elsif (arch =~ /ia(.*)64/)
  package_name = 'ucsmgria64'
end


if ['debian', 'rhel', 'fedora', 'freebsd', 'arch', 'suse'].include?(node['platform_family'])
  
  # copy service manager archive to temp location
  cookbook_file "#{cache_path}/ucsmgr.tar.gz" do
    source "#{package_name}.tar.gz"
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
    source "#{package_name}.zip"
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

  # execute service manager to install to Windows Service
  windows_batch "install-service" do
    code "#{smgr_path}\\bin\\ucybsmgr.exe -install uc4 -i#{smgr_path}\\bin\\ucybsmgr.ini"
  end
 
  # start UC4 service
  service "UC4.ServiceManager.uc4" do
    action [:enable, :start]
  end

  # copy service manager dialog
  

  # invoke UCYBSMCI to start UC4 Agent

end
