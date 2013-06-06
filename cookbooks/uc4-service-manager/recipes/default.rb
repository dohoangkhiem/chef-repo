#
# Cookbook Name:: uc4-service-manager
# Recipe:: default
#
# Copyright 2013, UC4 Software
#
# All rights reserved - Do Not Redistribute
#

# installation location on node
smgr_dest = node['uc4servicemanager']['path']

# determine package to install based on the processor architecture
arch = node['kernel']['machine']

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
  cookbook_file "/tmp/smgr.tar.gz" do
    source "linux/#{package_name}.tar.gz"
    mode 00755
    action :create
  end

  directory node['uc4servicemanager']['path'] do
    owner 'root'
    group 'root'
    mode 00755
    recursive true
    action :create
  end

  execute "extract" do
    command "tar xzvf /tmp/smgr.tar.gz -C #{smgr_dest}"
    action :run
  end

  execute "change-owner" do
    command "chown -R root:root #{smgr_dest}/*"
    action :run
  end

  template "#{smgr_dest}/bin/ucybsmgr.ini" do
    source "ucybsmgr.ini.erb"
    mode 0644
    #notifies :run, 'execute[start-service]', :immediately
  end

  execute "start-service" do
    command "#{smgr_dest}/bin/ucybsmgr"
    action :run
  end

  # cleanup
  file "/tmp/smgr.tar.gz" do
    action :delete
  end
end

if platform?("windows")
  directory "C:\\uc4\\temp" do
    recursive true
    action :create
  end
  
  cookbook_file "C:\\uc4\\temp\\smgr.zip" do
    source "#{package_name}.zip"
    action :create
  end
  
  # Extract service manager to destination
  windows_zipfile node['uc4servicemanager']['path'] do 
    source "C:\\uc4\\temp\\smgr.zip"
    action :unzip
  end

  template "#{smgr_dest}\\bin\\ucybsmgr.ini" do
    source "ucybsmgr.ini.erb"
  end

  # execute service manager to install to Windows Service
  windows_batch "install-service" do
    code "#{smgr_dest}\\bin\\ucybsmgr.exe -install -iC #{smgr_dest}\\bin\\ucybsmgr.ini"
  end
 
  # start UC4 service
  service "UC4.ServiceManager.uc4" do
    action [:enable, :start]
  end

  # cleanup
  file "C:\\uc4\\temp\\smgr.zip" do
    action :delete
  end

end
