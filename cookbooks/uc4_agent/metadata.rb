name             'uc4_agent'
maintainer       'UC4 Software'
maintainer_email 'kdh@uc4.com'
license          'All rights reserved'
description      'Installs/Configures UC4 Agent, Service Manager'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '1.0.0'

recipe "uc4_agent::default", "Installs the UC4 Agent and Service Manager and ensures that the agent is running"
recipe "uc4_agent::agent", "Installs the UC4 Agent"
recipe "uc4_agent::service_manager", "Installs UC4 Service Manager/Service Manager Dialog, agent recipe is included also"

%w{ unix linux debian ubuntu centos redhat scientific fedora amazon arch oracle freebsd windows }.each do |os|
  supports os
end

depends "windows"
