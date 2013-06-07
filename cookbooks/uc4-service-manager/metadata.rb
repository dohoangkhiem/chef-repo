name             'uc4-service-manager'
maintainer       'UC4'
maintainer_email 'kdh@uc4.com'
license          'All rights reserved'
description      'Installs/Configures UC4 Service Manager'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

recipe "uc4-service-manager", "Installs UC4 Service Manager and ensures that it is running"
recipe "uc4-service-manager::dialog", "Installs UC4 Service Manager Dialog, for Windows host only"

%w{ unix linux debian ubuntu centos redhat scientific fedora amazon arch oracle freebsd windows }.each do |os|
  supports os
end

depends "windows"
