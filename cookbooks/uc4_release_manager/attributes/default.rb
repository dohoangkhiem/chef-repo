# Attributes for this cookbook
=begin
uc4releasemanager/system_folder	The name of the folder in which the targets should be created	initial only	Text	 	yes 
uc4releasemanager/system_owner	The owner of the target 	 	Text	 	yes 
uc4releasemanager/system_environment	The environment of the targets 	 	Text	 	yes 
uc4releasemanager/system_agent	The name of the agent	 	Text	
node['uc4agent']['name']
no 
=end

node.default['uc4releasemanager']['system_folder'] = ''
node.default['uc4releasemanager']['system_owner'] = ''
node.default['uc4releasemanager']['system_environment'] = ''

node.default['uc4releasemanager']['system_agent'] = node['uc4agent']['name']

# Default attribute for Tomcat recipe

node.default['uc4releasemanager']['tomcat']['system_folder'] = node['uc4releasemanage']['system_folder']
node.default['uc4releasemanager']['tomcat']['system_owner'] = node['uc4releasemanage']['system_owner']
node.default['uc4releasemanager']['tomcat']['system_environment'] = node['uc4releasemanage']['system_environment']

