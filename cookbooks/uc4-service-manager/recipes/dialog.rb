#
# Cookbook Name:: uc4-service-manager
# Recipe:: dialog
#
# Copyright 2013, UC4 Software
#
# All rights reserved - Do Not Redistribute
#

if platform? "windows"
  directory "C:\\uc4\\temp" do
    recursive true
    action :create
  end
  
  arch = node['kernel']['machine']

  if (arch =~ /i(.{1})86/)
    # x86 package
    package_name = 'ucsmdx86'
  elsif (arch =~ /x(.*)64/)
    package_name = 'ucsmdx64'
  elsif (arch =~ /ia(.*)64/)
    package_name = 'ucsmdia64'
  end
  
  cookbook_file "C:\\uc4\\temp\\smd.zip" do
    source "#{package_name}.zip"
    action :create
  end

  # Extract service manager dialog to destination
  windows_zipfile node['uc4servicemanager']['path_dialog'] do 
    source "C:\\uc4\\temp\\smd.zip"
    action :unzip
  end

  # cleanup
  file "C:\\uc4\\temp\\smd.zip" do
    action :delete
  end
end
