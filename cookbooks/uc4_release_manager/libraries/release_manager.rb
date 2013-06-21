require 'rubygems'
require 'rexml/document'
require 'csv'
require 'chef/provider/package'

module ReleaseManager

  @@WSDL_PATH = "/service/ImportExportService.asmx?wsdl"

  @@url = ''
  @@username = ''
  @@password = ''
  @@client = nil
  @@initialized = false

  # init connection info, soap client
  def self.init_rm()
    connection_info = Chef::DataBagItem.load("uc4_release_manager", "connection")
    @@url = connection_info['url']
    @@username = connection_info['username']
    @@password = connection_info['password']

    # try to install savon 2.2.0
    (Chef::Provider::Package::Rubygems::GemEnvironment.new).install "savon", "version" => "2.2.0"
    require 'savon'

    @@client = Savon.client(wsdl: @@url + @@WSDL_PATH)
    @@initialized = true
  end
  
  # check if deployment target exists or not 
  def self.deployment_target_exist?(name_or_id)
    
    self.init_rm unless @initialized
    
    Chef::Log.info("Checking existence of deployment target name '#{name_or_id}'..")

    # try export deployment target
    begin
      message = { "username" => @@username, "password" => @@password, "mainType" => "DeploymentTarget", "format" => "CSV", "begin" => 0, "count" => 1, 
                  "properties" => { :string => "system_name" }, "conditions" => { :string => "system_name eq '#{name_or_id}'" } }
      response = @@client.call(:export, message: message)
      
      token = response.body[:export_response][:export_result][:token]
      Chef::Log.debug("Got token: #{token}")

      # retrieve data via GetStatus service
      while true
        response = @@client.call(:get_status, message: { "token" => token })
        sleep 1
        if response.body[:get_status_response][:get_status_result][:status] != 0
          break
        end
      end
      
      data = response.body[:get_status_response][:get_status_result][:data]
      if not data.nil? and data.lines.count > 1      
        Chef::Log.info("Deployment target #{name_or_id} already exists.")
        return true
      else
        Chef::Log.info("No deployment target name '#{name_or_id}'")
        return false
      end
  
    rescue Exception => e
      Chef::Log.info("Failed to check deployment target #{name_or_id}. We will assume that this target does not exist.")
      Chef::Log.debug(e.message)
      Chef::Log.debug(e.backtrace.inspect)
      false
    end
  end

  # create or update deployment target
  def self.create_deployment_target(name, type, folder, owner, environment, agent, props, dynamic_props, update_system_properties)  
   
    self.init_rm unless @initialized

    exclude_system_props = false
    if not update_system_properties
      # check existence of target
      # if target exists, just update agent, props, dynamic props
      exclude_system_props = true if self.deployment_target_exist?(name)
    end

    Chef::Log.info("Importing deployment target..")
    
    doc = REXML::Document.new '<?xml version="1.0" encoding="UTF-8"?>'
    root = doc.add_element 'Sync', { "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance" }
    entity = root.add_element "Entity", { "mainType" => "DeploymentTarget", "customType" => type }

    if exclude_system_props
      Chef::Log.info("Exclude system properties due to update_system_properties = false")
      prop_hash = { "system_name" => name, "system_deployment_agent_name" => agent }
    else
      prop_hash = { "system_name" => name, "system_owner.system_name" => owner, "system_folder.system_name" => folder, "system_deployment_agent_name" => agent,
                  "system_description" => "created via RM Chef cookbook", "system_is_active" => "true" }
    end

    # add custom properties
    prop_hash = prop_hash.merge(props)    

    prop_hash.keys.each do |prk|
      prop_ele = entity.add_element "Property", { "name" => prk }
      if prk == 'system_name'
        prop_ele.add_attribute "isIdentity", "true"
      end
      value_ele = prop_ele.add_element "Value"
      value_ele.add_text "#{prop_hash[prk]}"
    end
  
    message = { "username" => @@username, "password" => @@password, "mainType" => "DeploymentTarget", "failOnError" => true, "fomat" => "XML", "data" => doc.to_s }
    
    response = @@client.call(:import, message: message)

    # check error and status
    status = response.body[:import_response][:import_result][:status].to_i 
    token = response.body[:import_response][:import_result][:token]

    Chef::Log.debug("Got token: #{token}")
    
    # wait for target id return
    while status == 0
      sleep 1
      response = @@client.call(:get_status, message: { "token" => token } )
      status = response.body[:get_status_response][:get_status_result][:status].to_i 
    end

    if status < 0
      Chef::Log.info("Unsuccessfully create or update deployment target")
      error = response.body[:get_status_response][:get_status_result][:error]    
      if not error.nil? and not error.empty?
        Chef::Log.info("Error detail: " + error.to_s)
      end
     return status
    end

    Chef::Log.info("Deployment target import successfully")
    
    # add environment
    if not exclude_system_props and not environment.nil? and not environment.empty?
      begin
        env_id = self.get_environment_id(environment)
        if (env_id > 0)
          self.add_environment_relation(env_id, name)
        end
      rescue Exception => e
        Chef::Log.info("Error occurred while updating environment for deployment target")    
        Chef::Log.debug(e.message)
        Chef::Log.debug(e.backtrace.inspect)
      end
    end

    # update dynamic properties
    if not dynamic_props.nil? and not dynamic_props.empty?
      begin
        self.update_dynamic_properties(status, dynamic_props)
      rescue Exception => e
        Chef::Log.info("Error occurred while updating dynamic properties for deployment target")    
        Chef::Log.debug(e.message)
        Chef::Log.debug(e.backtrace.inspect)
      end
    end

    return status
  end

  # retrives environment id from its name
  def self.get_environment_id(name)

    self.init_rm unless @initialized

    Chef::Log.info("Getting environment id from name '#{name}'")
          
    message = { "username" => @@username, "password" => @@password, "mainType" => "Environment", "format" => "CSV", "begin" => 0, "count" => 1, 
                "properties" => { :string => "system_id" }, "conditions" => { :string => "system_name eq '#{name}'" } }
    
    response = @@client.call(:export, message: message)
    
    token = response.body[:export_response][:export_result][:token]
    Chef::Log.debug("Got token: #{token}")

    while true
      response = @@client.call(:get_status, message: { "token" => token })
      if response.body[:get_status_response][:get_status_result][:status] != 0
        break
      end
      sleep 1
    end
    
    Chef::Log.debug("Get Status SOAP response: " + response.to_s)
    
    data = response.body[:get_status_response][:get_status_result][:data]
    
    if data.lines.count < 2
      Chef::Log.info("Environment not found: #{name}. Skip environment import.")
      return -1
    end

    env_id = data.split("\n")[1].split(",")[-1]
    return env_id.to_i
  end

  # add environment relation to target
  def self.add_environment_relation(env_id, target_name)

    self.init_rm unless @initialized

    Chef::Log.info("Adding environment relation to target'#{target_name}'..")

    # add environment relation to target
    csv_string = CSV.generate do |csv|
      csv << ["system_environment.system_id", "system_deployment_target.system_name"]
      csv << [env_id, target_name]
    end

    message = { "username" => @@username, "password" => @@password, "mainType" => "EnvironmentDeploymentTargetRelation", "failOnError" => true, "fomat" => "CSV", "data" => csv_string}
    response = @@client.call(:import, message: message)

    status = response.body[:import_response][:import_result][:status].to_i 
    
    token = response.body[:import_response][:import_result][:token]

    Chef::Log.debug("Got token: #{token}")
    
    #while status == 0
    #  sleep 1
    #  response = @@client.call(:get_status, message: { "token" => token } )
    #  status = response.body[:get_status_response][:get_status_result][:status].to_i 
    #end

    error = response.body[:import_response][:import_result][:error]    

    if status < 0
      Chef::Log.info("Unsuccessfully add environment id #{env_id} to target #{target_name}")
      if not error.nil? and not error.empty?
        Chef::Log.info("Error detail: " + error.to_s)
      end
      return
    end
    
    Chef::Log.info("Environment update finished")
  end

  # update dynamic properties of given target
  def self.update_dynamic_properties(target_id, dynamic_props)
    self.init_rm unless @initialized
      
    Chef::Log.info("Updating dynamic properties for target #{target_id} ..")
  
    doc = REXML::Document.new '<?xml version="1.0" encoding="UTF-8"?>'
    root = doc.add_element 'Sync', { "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance" }

    dynamic_props.keys.each do |dpk|
      next if dpk.nil? or dpk.empty?
      dpk_props = dynamic_props[dpk]
      type = dpk_props['type']
      type = (type.nil? or type.empty?) ? "SingleLineText" : type

      fullname = dpk_props['namespace']
      fullname = "/" + fullname unless fullname.start_with?("/")
      if fullname.end_with?("/") 
        fullname = fullname + dpk      
      else
        fullname = fullname + '/' + dpk
      end
      prop_hash = { "system_on_entity.system_id" => target_id, "system_on_maintype" => "DeploymentTarget", "system_full_name" =>  fullname, "system_type" => type }

      prop_hash['system_value'] = dpk_props['value'] if dpk_props['value']
      prop_hash['system_description'] = dpk_props['description']

      entity = root.add_element "Entity", { "mainType" => "DynamicProperty" }
      prop_hash.keys.each do |prk|
        prop_ele = entity.add_element "Property", { "name" => prk }
        if prk == 'system_full_name' or prk == 'system_on_entity.system_id' or prk == 'system_on_maintype'
          prop_ele.add_attribute "isIdentity", "true"
        end
        value_ele = prop_ele.add_element "Value"
        value_ele.add_text "#{prop_hash[prk]}"
      end
    end

    Chef::Log.debug(doc.to_s)
  
    message = { "username" => @@username, "password" => @@password, "mainType" => "DynamicProperty", "failOnError" => false, "fomat" => "XML", "data" => doc.to_s }
    
    response = @@client.call(:import, message: message)

    # check error and status
    status = response.body[:import_response][:import_result][:status].to_i 
    token = response.body[:import_response][:import_result][:token]

    Chef::Log.debug("Got token: #{token}")
    
    if status < 0
      Chef::Log.info("Unsuccessfully update dynamic property for target #{target_id}")
      error = response.body[:import_response][:import_result][:error]    
      if not error.nil? and not error.empty?
        Chef::Log.info("Error detail: " + error.to_s)
      end
      return
    end
    
    Chef::Log.info("Dynamic properties update finished")
  end

end
