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

  # prepare connection info
  def self.init_connection()
    # try to install savon 2.2.0
    (Chef::Provider::Package::Rubygems::GemEnvironment.new).install "savon", "version" => "2.2.0"
    require 'savon'

    connection_info = Chef::DataBagItem.load("uc4_release_manager", "connection")
    @@url = connection_info['url']
    @@username = connection_info['username']
    @@password = connection_info['password']
    @@client = Savon.client(wsdl: @@url + @@WSDL_PATH)
    @@initialized = true
  end
  
  # check if deployment target exists or not 
  def self.deployment_target_exist?(name_or_id)

    unless @@initialized 
      self.init_connection
    end
    
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
      if data.lines.count > 1      
        Chef::Log.info("Deployment target #{name_or_id} already exists.")
        return true
      else
        Chef::Log.info("No deployment target name '#{name_or_id}'.")
        return false
      end
  
    rescue Exception => e
      Chef::Log.info("Failed to check deployment target #{name_or_id}. We will assume that this target does not exist.")
      Chef::Log.info(e.message)
      Chef::Log.debug(e.backtrace.inspect)
      false
    end
  end

  # create deployment target
  def self.create_deployment_target(name, type, folder, owner, environment, agent, props, dynamic_props)  
    unless @@initialized 
      self.init_connection
    end

    Chef::Log.info("Creating deployment target..")
    
    # create or update deployment target
    #TODO Use XML data instead
    csv_string = CSV.generate do |csv|
      csv << ["system_name", "system_owner.system_name", "system_folder.system_name", "system_deployment_agent_name", "system_description", "system_custom_type", "system_is_active",      "system_identity_properties"] # + ((props.nil? or props.empty?) ? [] : props.keys) + ((dynamic_props.nil? or dynamic_props.empty?) ? [] : dynamic_props.keys)
      csv << [name, owner, folder, agent, "created via RM Chef cookbook", type, "true", "system_name"] # + (props.nil? ? [] : props.values) + (dynamic_props.nil? ? [] : dynamic_props.values)
    end
     
    message = { "username" => @@username, "password" => @@password, "mainType" => "DeploymentTarget", "failOnError" => true, "fomat" => "CSV", "data" => csv_string }
    response = @@client.call(:import, message: message)

    # check error and status
    target_id = response.body[:import_response][:import_result][:status].to_i 
    error = response.body[:import_response][:import_result][:error]    

    if target_id <= 0
      Chef::Log.info("Unsuccessfully create or update deployment target")
      if !error.empty?
        Chef::Log.info("Error detail: " + error.to_s)
      end
    end
  
    if not environment.nil? and not environment.empty?
      env_id = self.get_environment_id(environment)
      if (env_id > 0)
        self.add_environment_relation(env_id, name)
      end
    end

    # return system_id
    return target_id
  end

  # retrives environment id from its name
  def self.get_environment_id(name)

    unless @@initialized 
      self.init_connection
    end

    Chef::Log.info("Getting environment id from name '#{name}'")
          
    message = { "username" => @@username, "password" => @@password, "mainType" => "Environment", "format" => "CSV", "begin" => 0, "count" => 1, 
                "properties" => { :string => "system_id" }, "conditions" => { :string => "system_name eq '#{name}'" } }
    
    response = @@client.call(:export, message: message)
    
    token = response.body[:export_response][:export_result][:token]
    Chef::Log.debug("Got token: #{token}")

    while true
      response = @@client.request :wsdl, :get_status do |soap|
        soap.body = { "token" => token }
      end
      sleep 1
      if response.body[:get_status_response][:get_status_result][:status] != 0
        break
      end
    end
    
    Chef::Log.debug("SOAP Response: " + response.to_hash)
    
    data = response.body[:get_status_response][:get_status_result][:data]
    
    if data.lines.count < 2
      Chef::Log.info("Failed to get environment id")
      return -1
    end

    env_id = data.split("\n")[1].split(",")[-1]
    return env_id
  end

  # add environment relation to target
  def self.add_environment_relation(env_id, target_name)

    unless @@initialized 
      self.init_connection
    end

    Chef::Log.info("Adding environment relation to target'#{target_name}'")

    # add environment relation to target
    csv_string = CSV.generate do |csv|
      csv << ["system_environment.system_id", "system_deployment_target.system_name"]
      csv << [env_id, target_name]
    end

    message = { "username" => @@username, "password" => @@password, "mainType" => "EnvironmentDeploymentTargetRelation", "failOnError" => true, "fomat" => "CSV", "data" => csv_string}
    response = @@client.call(:import, message: message)

    status = response.body[:import_response][:import_result][:status] 
    error = response.body[:import_response][:import_result][:error]    

    if status <= 0
      Chef::Log.info("Unsuccessfully add environment id #{env_id} to target #{target_name}")
      if not error.empty?
        Chef::Log.info("Error detail: " + error.to_s)
      end
    end
  end

end
