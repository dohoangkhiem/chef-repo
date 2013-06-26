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
uc4_release_manager_rm_deployment_target target_name do
  owner owner
  folder folder
  environment "Test"
  agent agent
  type "Tomcat"
  property ({ port: node['tomcat']['port'], home_directory: node['tomcat']['base'] }) # key as property name, value as property value
  dynamic_property ({ author: { type: "SingleLineText", namespace: "/the/name/space", value: "Khiem Do Hoang" }, # key as dynamic property name, value is a hash contains type, namespace, value, ... of dynamic property
                      version: { type: "SingleLineText", namespace: "/another/name/space/", value: "1.2.7" },
                      organization: { type: "SingleLineText", namespace: "/another/name/space/", value: "uc4" }
                   })
  action :create
  update_system_properties false
  #not_if { ReleaseManager.deployment_target_exist?(target_name) }
end


