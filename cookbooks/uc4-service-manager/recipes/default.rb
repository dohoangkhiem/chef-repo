#
# Cookbook Name:: uc4-service-manager
# Recipe:: default
#
# Copyright 2013, UC4 Software
#
# All rights reserved - Do Not Redistribute
#

smgr_dest = node['uc4servicemanager']['path']

if ['debian', 'rhel', 'fedora', 'freebsd', 'arch'].include?(node['platform_family'])
  
  # copy service manager archive to temp location
  cookbook_file "/tmp/smgr.tar.gz" do
    source "smgr.tar.gz"
    mode 00755
    action :create
  end

  execute "extract" do
    command "mkdir -p #{smgr_dest} && tar xzvf /tmp/smgr.tar.gz -C #{smgr_dest}"
    action :run
  end

  execute "configure" do
    command "echo Finished configuring UC4 Service Manager"
    action :nothing
  end

  template "#{smgr_dest}/bin/ucybsmgr.ini" do
    source "ucybsmgr.ini.erb"
    mode 0644
    notifies :run, 'execute[configure]', :immediately
  end

  execute "cleanup" do
    command "rm /tmp/smgr.tar.gz"
    action :run
  end

end

if platform?("windows")
  # execute Ruby block to extract service manager to destination node
  
end
