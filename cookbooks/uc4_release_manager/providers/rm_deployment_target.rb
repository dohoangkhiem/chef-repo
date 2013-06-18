action :create do
  name = new_resource.name
  type = new_resource.type
  folder = new_resource.folder
  owner = new_resource.owner
  environment = new_resource.environment

  props = new_resource.property
  dynamic_props = new_resource.dynamic_property
  update_system_properties = new_resource.update_system_properties

  # mapping: target type => Chef cookbook(s)
  cookbook_type_map = { "tomcat" => "tomcat", "database generic" => ["postgresql", "database"], "database mssql" => ["sql_server", "database"], "database oracle" => "database", "iis" => "iis", "filebased" => "", "weblogic" => "", "generic" => "", "jboss" => "", "staging" => "", "websphere" => "" }

  type = type.downcase
  # check runlist of node
  if !cookbook_type_map.has_key?(type)
    Chef::Log.info("The target type '#{type}' is not supported")
    new_resource.updated_by_last_action(false)
    return
  end
   
  Chef::Log.info("Checking cookbook mapping for target type '#{type}'")
  mapped_cookbooks = cookbook_type_map[type]
  
  unless mapped_cookbooks.empty? 
    if mapped_cookbooks.kind_of?(Array)
      # check if run list of node contains one of cookbook from mapped cookbooks
      found = false
      mapped_cookbooks.each do |cb|
        if node['recipes'].include? "recipe[#{cb}]"
          Chef::Log.info("Found cookbook #{cb} on node")
          found = true
          break
        end
      end

      if !found
        Chef::Log.info("Can't find any mapped cookbook from node run list, exiting..")
        new_resource.updated_by_last_action(false)
        return
      end
    else
      if not node['recipes'].include? "recipe[#{mapped_cookbooks}]"
        Chef::Log.info("Can't find any mapped cookbook from node run list, exiting..")
        new_resource.updated_by_last_action(false)
        return
      end
    end
  end
  
  # init ReleaseManager with connection information from data bag 
  connection_info = data_bag_item("uc4_release_manager", "connection")
  ReleaseManager.set_connection_info(connection_info['url'], connection_info['username'], connection_info['password']) 

  Chef::Log.info("Creating new deployment target #{name}..")

  begin 
    system_id = ReleaseManager.create_deployment_target(name, type, folder, owner, environment, agent, props, dynamic_props)
    if system_id > 0
      Chef::Log.info("Successfully created/updated deployment target")
      node['uc4releasemanager']['tomcat']['system_id'] = system_id
      node['uc4releasemanager']['tomcat']['system_name'] = name
      new_resource.updated_by_last_action(true)
    else
       new_resource.updated_by_last_action(false)
    end
  rescue Exception => e
    Chef::Log.info("Failed to create or update deployment target #{name}")
    Chef::Log.info(e.message)
    Chef::Log.debug(e.backtrace.inspect)
    new_resource.updated_by_last_action(false)
  end
 
end
