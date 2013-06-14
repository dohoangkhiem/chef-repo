action :create do
  name = new_resource.name
  type = new_resource.type
  folder = new_resource.folder
  owner = new_resource.owner

  # parse property & dynamic_property value
  property = new_resource.property
  dynamic_property = new_resource.dynamic_property
  update_system_properties = new_resource.update_system_properties

  # check if the deployment target exists to update
  if UC4::ReleaseManager.deployment_target_exist?(name)
    # update deployment target
    
    Chef::Log.info("Deployment target #{name} exists. Trying update target..")
    
  else
    # if not, create new deployment target
    Chef::Log.info("Creating new deployment target #{name}..")
    
  end   

  new_resource.updated_by_last_action(true)
 
end
