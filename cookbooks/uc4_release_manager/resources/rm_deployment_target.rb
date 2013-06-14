actions :create

default_action :create if defined?(:default_action) # Chef > 10.8

attribute :name, :kind_of => String, :name_attribute => true, :required => true
attribute :type, :kind_of => String, :required => true
attribute :owner, :kind_of => String, :required => true
attribute :folder, :kind_of => String, :required => true
attribute :environment, :kind_of => String
attribute :agent, :kind_of => String
attribute :property, :kind_of => Hash
attribute :dynamic_property, :kind_of => Hash
attribute :update_system_properties, :kind_of => [TrueClass, FalseClass], :default => true

# Default action for Chef <= 10.8
def initialize(*args)
  super
  @action = :create
end
