chef_gem "savon"

# collect attributes

node.override['uc4releasemanager']['tomcat']['system_folder'] = "D_X1"
node.override['uc4releasemanager']['tomcat']['system_owner'] = ""
node.override['uc4releasemanager']['tomcat']['system_environment'] = ""

target_name = node['uc4releasemanager']['system_agent'] + " Tomcat server" 
owner = node['uc4releasemanager']['tomcat']['system_owner']
folder = node['uc4releasemanager']['tomcat']['system_folder']
environment = node['uc4releasemanager']['tomcat']['system_environment']

agent = node['uc4releasemanager']['system_agent']

if !node['recipes'].include?("recipe[tomcat]")
  Chef::Application.fatal!("No Tomcat recipe on this node, exiting..")
end

# create deployment target
rm_deployment_target "#{target_name}" do
  owner "#{owner}"
  folder "#{folder}"
  environment "#{environment}"
  agent "#{agent}"
  type "Tomcat"
  property ({ "port" => node['tomcat']['port'], "base_directory" => node['tomcat']['base_dir'] })
  action :create
end


