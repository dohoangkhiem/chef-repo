name             'uc4_release_manager'
maintainer       'UC4 Software'
maintainer_email 'kdh@uc4.com'
license          'All rights reserved'
description      'Installs/Configures deployment target in Release Manager'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

recipe "uc4_release_manager::default", "Nothing now"
recipe "uc4_release_manager::tomcat", "Create/Update tomcat deployment target"

%w{ unix linux debian ubuntu centos redhat scientific fedora amazon arch oracle freebsd windows }.each do |os|
  supports os
end

depends "uc4_agent"

