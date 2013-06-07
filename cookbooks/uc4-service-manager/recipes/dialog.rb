#
# Cookbook Name:: uc4-service-manager
# Recipe:: dialog
#
# Copyright 2013, UC4 Software
#
# All rights reserved - Do Not Redistribute
#

smd_dest = node['uc4servicemanager']['path_dialog']
cache_path = Chef::Config[:file_cache_path]

if platform? "windows"
  arch = node['kernel']['machine']

  if (arch =~ /i(.{1})86/)
    # x86 package
    package_name = 'ucsmdx86'
  elsif (arch =~ /x(.*)64/)
    package_name = 'ucsmdx64'
  elsif (arch =~ /ia(.*)64/)
    package_name = 'ucsmdia64'
  end
  
  cookbook_file "#{cache_path}\\smd.zip" do
    source "#{package_name}.zip"
    action :create_if_missing
  end

  # Extract service manager dialog to destination
  windows_zipfile node['uc4servicemanager']['path_dialog'] do 
    source "#{cache_path}\\smd.zip"
    action :unzip
    not_if {::File.exists?("#{smd_dest}\\bin\\ucybsmdi.exe")}
  end

end
