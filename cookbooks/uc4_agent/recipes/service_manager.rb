#
# Cookbook Name:: uc4-agent
# Recipe:: service_manager
#
# Copyright 2013, UC4 Software
#
# All rights reserved - Do Not Redistribute
#

include_recipe "uc4_agent::agent"

# Install UC4 Service Manager

cache_path = Chef::Config[:file_cache_path]

arch = node['kernel']['machine']

smgr_path = node['uc4servicemanager']['path']

phrase = node['uc4servicemanager']['phrase']

if (arch =~ /i(.{1})86/)
  file_suffix = 'i3'
elsif (arch =~ /x(.*)64/)
  file_suffix = 'x6'
elsif (arch =~ /ia(.*)64/)
  file_suffix = 'i6'
else 
  raise "No support for this architecture: #{arch}"
end

if ['debian', 'rhel', 'fedora', 'freebsd', 'arch', 'suse'].include?(node['platform_family'])
  
  # copy service manager archive to temp location
  cookbook_file "#{cache_path}/ucsmgr.tar.gz" do
    source "ucsmgrl#{file_suffix}.tar.gz"
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

  # adopt service manager configuration file
  template "#{smgr_path}/bin/ucybsmgr.ini" do
    source "ucybsmgr.ini.erb"
    mode 0644
  end

  uc4_service_name = "UC4 Unix-Agent"
  # template SMC and SMD files
  template node['uc4servicemanager']['smd_file'] do
    source "uc4.smd.erb"
    mode 0644
    variables(
      :uc4_service_name => "#{uc4_service_name}",
      :executable_file => "ucxjl#{file_suffix}",
      :ini_file => "ucxjl#{file_suffix}.ini"
    )
  end

  # adopt SMC file only if node['uc4agent']['servicemanager_autostart'] was configured to 'yes'
  if node['uc4agent']['servicemanager_autostart'] == 'yes'
    template node['uc4servicemanager']['smc_file'] do
      source "uc4.smc.erb"
      mode 0644
      variables(
        :uc4_service_name => "#{uc4_service_name}",
        :delay => node['uc4agent']['servicemanager_autostart_delay']
      )
    end
  end

  # start UC4 service manager
  execute "start-service" do
    cwd "#{smgr_path}/bin"
    command "./ucybsmgr -iucybsmgr.ini '#{phrase}' &"
    action :run
  end

  # start agent if no smc file adopted
  unless node['uc4agent']['servicemanager_autostart'] == 'yes'
    execute "start-agent" do
      cwd "#{smgr_path}/bin"
      command "./ucybsmcl -c START_PROCESS -h " + node['hostname'] + ":" + node['uc4servicemanager']['port'] + " -n #{phrase} -s \"#{uc4_service_name}\""
      action :run
    end
  end
  
end

# For Windows node
if platform?("windows")  
  cookbook_file "#{cache_path}\\ucsmgr.zip" do
    source "ucsmgrw#{file_suffix}.zip"
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

  uc4_service_name = "UC4 Windows-Agent"

  # Templating SMD file
  template node['uc4servicemanager']['smd_file'] do
    source "UC4.smd.erb"
    variables(
      :uc4_service_name => "#{uc4_service_name}",
      :executable_file => "ucxjw#{file_suffix}.exe",
      :ini_file => "ucxjw#{file_suffix}.ini"
    )
  end

  # adopt SMC file only if node['uc4agent']['servicemanager_autostart'] was configured to 'yes'
  if node['uc4agent']['servicemanager_autostart'] == 'yes'
    template node['uc4servicemanager']['smc_file'] do
      source "uc4.smc.erb"
      mode 0644
      variables(
        :uc4_service_name => "#{uc4_service_name}",
        :delay => node['uc4agent']['servicemanager_autostart_delay']
      )
    end
  end

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
    source "ucsmdw#{file_suffix}.zip"
    action :create_if_missing
  end

  # extract service manager dialog
  windows_zipfile node['uc4servicemanager']['path_dialog'] do 
    source "#{cache_path}\\ucsmd.zip"
    action :unzip
    not_if {::File.exists?(::File.join(node['uc4servicemanager']['path_dialog'], "bin", "UCYBSMCl.exe"))}
  end

  # config Powershell, optional
  windows_batch "config-powershell" do
    code node['kernel']['os_info']['system_directory'] + "\\WindowsPowerShell\\v1.0\\powershell.exe Set-ExecutionPolicy Unrestricted -scope CurrentUser"
    action :run
    ignore_failure true
  end

  hostname = node['hostname']
  # invoke UCYBSMCl to start UC4 Agent
  # TODO: Re-check this action, maybe it's not neccessary if node['uc4agent']['servicemanager_autostart'] == 'yes', as the service manager invoked agent before
  unless node['uc4agent']['servicemanager_autostart'] == 'yes'
    windows_batch "start-agent" do
      cwd ::File.join(node['uc4servicemanager']['path_dialog'], "bin")
      code "UCYBSMCl.exe -c START_PROCESS -h #{hostname} -n #{phrase} -s \"#{uc4_service_name}\""
      action :run
    end
  end
end
