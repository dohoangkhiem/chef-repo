def whyrun_supported?
  true
end

use_inline_resources

action :create do
  name = new_resource.name
  type = new_resource.type
  folder = new_resource.folder
  agent = new_resource.agent
  owner = new_resource.owner
  environment = new_resource.environment

  props = new_resource.property
  dynamic_props = new_resource.dynamic_property
  update_system_properties = new_resource.update_system_properties

  if name.empty? or type.empty? or folder.empty? or owner.empty?
    Chef::Application.fatal!("Name, type, folder and owner must not be empty!")
  end
  
  # mapping: target type => Chef cookbook(s)
  cookbook_type_map = { "tomcat" => "tomcat", "database generic" => ["postgresql", "database"], "database mssql" => ["sql_server", "database"], "database oracle" => "database", "iis" => "iis", "filebased" => "", "weblogic" => "", "generic" => "", "jboss" => "", "staging" => "", "websphere" => "" }

  type = type.downcase
  # check runlist of node
  if !cookbook_type_map.has_key?(type)
    new_resource.updated_by_last_action(false)
    Chef::Application.fatal!("The target type '#{type}' is not supported")
  end
   
  mapped_cookbooks = cookbook_type_map[type]
  
  unless mapped_cookbooks.empty? 
    if mapped_cookbooks.kind_of?(Array)
      # check if run list of node contains one of cookbook from mapped cookbooks
      found = false
      mapped_cookbooks.each do |cb|
        if node['recipes'].include? cb
          Chef::Log.info("Found cookbook #{cb} on node")
          found = true
          break
        end
      end

      if !found
        new_resource.updated_by_last_action(false)
        Chef::Application.fatal!("Can't find any mapped cookbook from node run list, supported types: #{cookbook_type_map.keys.join(', ')}")
      end
    else
      if not node['recipes'].include? mapped_cookbooks
        new_resource.updated_by_last_action(false)
        Chef::Application.fatal!("Can't find any mapped cookbook from node run list, supported types: #{cookbook_type_map.keys.join(', ')}")
      end
    end
  end
  
  # init ReleaseManager with connection information from data bag 
  Chef::Log.info("Initializing Release Manager client library..")
  begin
    ReleaseManager.init_rm  
  rescue Exception => e
    Chef::Log.info("Error occurred: #{e.message}")
    Chef::Log.debug(e.backtrace.inspect)
    new_resource.updated_by_last_action(false)
    Chef::Application.fatal!("Error: Failed to initialize Release Manager library!")
  end
  
  # due to the fact that AE always convert agent name to upper case
  agent = agent.upcase

  Chef::Log.info("Creating new deployment target #{name}..")
 
  begin 
    system_id = ReleaseManager.create_deployment_target(name, type, folder, owner, environment, agent, props, dynamic_props, update_system_properties)
    if system_id > 0
      Chef::Log.info("Successfully created/updated deployment target")
      node.override['uc4releasemanager']['tomcat']['system_id'] = system_id
      node.override['uc4releasemanager']['tomcat']['system_name'] = name
      new_resource.updated_by_last_action(true)
    else
       Chef::Log.info("Unsuccessful operation: Release Manager response status code = #{system_id}")
       new_resource.updated_by_last_action(false)
    end
  rescue Exception => e
    Chef::Log.info("Error occurred: #{e.message}")
    Chef::Log.debug(e.backtrace.inspect)
    new_resource.updated_by_last_action(false)
    Chef::Application.fatal!("Failed to create or update deployment target #{name}")
  end
 
end
