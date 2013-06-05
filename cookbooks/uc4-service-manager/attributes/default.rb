###
###

# default UC4 Service Manager attributes
default['uc4servicemanager']['port'] = '8871'
default['uc4servicemanager']['path_dialog'] = "C:\\uc4\\ServiceManagerDialog"
default['uc4servicemanager']['phrase'] = 'UC4'

case node['platform_family']
when "rhel", "fedora"
  default['uc4servicemanager']['path'] = "/opt/uc4/smgr"
when "freebsd"
  default['uc4servicemanager']['path'] = "/opt/uc4/smgr"
when "arch"
  default['uc4servicemanager']['path'] = "/opt/uc4/smgr"
when "windows"
  default['uc4servicemanager']['path'] = "C:\\uc4\\ServiceManager"
when "debian"
  default['uc4servicemanager']['path'] = "/opt/uc4/smgr"
else
  default['uc4servicemanager']['path'] = "/opt/uc4/smgr"
end

default['uc4servicemanager']['smc_file'] = "#{node['uc4servicemanager']['path']}/bin/UC4.smc"
default['uc4servicemanager']['smd_file'] = "#{node['uc4servicemanager']['path']}/bin/UC4.smd"


