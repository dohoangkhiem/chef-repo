###
# Merge Service Manager and Agent into 1 cookbook
###


# Default attributes for UC4 Service Manager
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

###
# Default UC4 Agent attributes
###
default['uc4agent']['port'] = '2300'
default['uc4agent']['systemname'] = "UC4"
default['uc4agent']['license_class'] = '1'

case node['platform_family']
when "windows"
  default['uc4agent']['path'] = "C:\\uc4\\agents\\windows"
else
  default['uc4agent']['path'] = "/opt/uc4/agent"
end

default['uc4agent']['user'] = "uc4"
default['uc4agent']['servicemanager'] = "yes"
default['uc4agent']['servicemanager_autostart'] = "no"
default['uc4agent']['servicemanager_autostart_delay'] = "0"

# other attributes
# default['uc4agent']['cp']
# default['uc4agent']['agentname']
# default['uc4agent']['servicemanager_data_bag_name']


