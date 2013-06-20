###

node.default['uc4releasemanager']['system_agent'] = node['hostname']

node.override['uc4releasemanager']['tomcat']['system_folder'] = "D_X1"
node.override['uc4releasemanager']['tomcat']['system_owner'] = ""
node.override['uc4releasemanager']['tomcat']['system_environment'] = ""

target_name = node['uc4releasemanager']['system_agent'] + " Tomcat server" 
owner = 'admin' #node['uc4releasemanager']['tomcat']['system_owner']
folder = node['uc4releasemanager']['tomcat']['system_folder']
environment = node['uc4releasemanager']['tomcat']['system_environment']

agent = node['uc4releasemanager']['system_agent']

if not node['recipes'].include?("tomcat")
  Chef::Application.fatal!("No Tomcat recipe on this node, exiting..")
end

# create deployment target
uc4_release_manager_rm_deployment_target "#{target_name}" do
  name target_name
  owner "#{owner}"
  folder "#{folder}"
  environment "#{environment}"
  agent "#{agent}"
  type "Tomcat"
  property ({ "port" => node['tomcat']['port'], "home_directory" => node['tomcat']['base'] })
  dynamic_property ({ "author" => { "type" => "SingleLineText", "namespace" => "/the/name/space", "value" => "Khiem Do Hoang" }, 
                      "version"=> { "type" => "SingleLineText", "namespace" =? "/another/nam/space/", "value" => "1.2.5" }                   
                   })
  action :create
  not_if { ReleaseManager.deployment_target_exist?(target_name) }
end


