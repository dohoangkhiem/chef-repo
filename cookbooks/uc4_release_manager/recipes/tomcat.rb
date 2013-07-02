###

if node['uc4releasemanager']['system_agent'].nil? or node['uc4releasemanager']['system_agent'].empty?
  target_name = "#{node['fqdn']} Tomcat server"
  agent = node['fqdn']
else
  target_name = node['uc4releasemanager']['system_agent'] + " Tomcat server" 
  agent = node['uc4releasemanager']['system_agent']
end

unless node['uc4releasemanager']['tomcat']['system_owner'].empty?
  owner = node['uc4releasemanager']['tomcat']['system_owner']
else
  owner = 'admin'
end

if node['uc4releasemanager']['tomcat']['system_folder'].empty?
  folder = "D_X1"  
else
  folder = node['uc4releasemanager']['tomcat']['system_folder']
end

environment = node['uc4releasemanager']['tomcat']['system_environment']

if not node['recipes'].include?("tomcat")
  Chef::Application.fatal!("No Tomcat recipe on this node, exiting..")
end

# create deployment target
# name, type, tomcat, folder are required
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


