#
# Cookbook Name:: uc4-agent
# Recipe:: default
#
# Copyright 2013, UC4 Software
#
# All rights reserved - Do Not Redistribute
#

include_recipe "uc4-agent::agent"
include_recipe "uc4-agent::service-manager"	
