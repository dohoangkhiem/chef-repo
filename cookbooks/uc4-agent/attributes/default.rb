###
###

# default UC4 Service Manager attributes
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


